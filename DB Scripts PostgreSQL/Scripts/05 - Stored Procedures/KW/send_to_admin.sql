DROP FUNCTION IF EXISTS kw_send_to_admin;

CREATE OR REPLACE FUNCTION kw_send_to_admin
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
    vr_admin_user_ids	guid_table_type[],
    vr_description	 	VARCHAR(2000),
    vr_now			 	TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_is_new_version		BOOLEAN DEFAULT FALSE;
	vr_wf_version_id 		INTEGER;
	vr_new_wf_version_id 	INTEGER;
	vr_version_id 			UUID;
	vr_result				INTEGER;
BEGIN
	/* Steps: */
	-- 1: Set knowledge status to 'SentToAdmin'
	-- 2: Create history
	-- 3: Send old evaluations to history
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	
	-- Check if is new workflow
	SELECT vr_is_new_version = TRUE
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id AND nd.status = 'Rejected'
	LIMIT 1;
	
	vr_wf_version_id := kw_fn_get_wf_version_id(vr_application_id, vr_node_id);
	vr_new_wf_version_id := vr_wf_version_id + (CASE WHEN vr_is_new_version = TRUE THEN 1 ELSE 0 END)::INTEGER;
	-- end of Check if is new workflow
	
	
	-- Set new knowledge status
	UPDATE cn_nodes AS nd
	SET status = 'SentToAdmin'
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of set new knowledge status
	
	
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		description,
		actor_user_id,
		action_date,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'SendToAdmin',
		vr_description,
		vr_current_user_id,
		vr_now,
		vr_new_wf_version_id,
		gen_random_uuid()
	);
	-- end of create history
	
	
	-- send old evaluations to history
	vr_version_id := gen_random_uuid();
	
	INSERT INTO kw_question_answers_history (
		application_id, 
		version_id, 
		knowledge_id, 
		user_id, 
		question_id,
		title, 
		score, 
		evaluation_date, 
		deleted, 
		selected_option_id, 
		version_date, 
		admin_score, 
		admin_selected_option_id, 
		admin_id, 
		wf_version_id
	)
	SELECT 	"a".application_id, 
			vr_version_id, 
			"a".knowledge_id, 
			"a".user_id, 
			"a".question_id, 
			"a".title, 
			"a".score, 
			"a".evaluation_date, 
			"a".deleted, 
			"a".selected_option_id, 
			vr_now, 
			"a".admin_score, 
			"a".admin_selected_option_id, 
			"a".admin_id, 
			vr_wf_version_id
	FROM kw_question_answers AS "a"
	WHERE "a".application_id = vr_application_id AND "a".knowledge_id = vr_node_id;
	
	DELETE FROM kw_question_answers AS qa
	WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_node_id;
	-- end of send old evaluations to history
	
	-- Remove all existing dashboards
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, 
													 vr_node_id, NULL, NULL, NULL);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	DROP TABLE IF EXISTS vr_dash_39023;
	
	CREATE TEMP TABLE vr_dash_39023 OF dashboard_table_type;
	
	INSERT INTO vr_dash_39023 (
		user_id, 
		node_id, 
		ref_item_id, 
		"type", 
		sub_type, 
		removable, 
		send_date, 
		"info"
	)
	SELECT	rf.value, 
			vr_node_id,
			vr_node_id,
			'Knowledge',
			'Admin',
			FALSE,
			vr_now,
			'{"WFVersionID":' || vr_new_wf_version_id::VARCHAR || '}'
	FROM UNNEST(vr_admin_user_ids) AS rf;
	
	vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
		SELECT d
		FROM vr_dash_39023 AS d
	));
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	ELSE
		RETURN QUERY
		SELECT d.*
		FROM vr_dash_39023 AS d;
	END IF;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

