DROP FUNCTION IF EXISTS kw_send_knowledge_comment;

CREATE OR REPLACE FUNCTION kw_send_knowledge_comment
(
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_user_id				UUID,
    vr_reply_to_history_id	BIGINT,
    vr_audience_user_ids	guid_table_type[],
    vr_description	 		VARCHAR(2000),
    vr_now			 		TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_creator_user_id	UUID;
	vr_username 		VARCHAR(1000);
	vr_first_name 		VARCHAR(1000);
	vr_last_name 		VARCHAR(1000);
	vr_result			INTEGER;
BEGIN
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		actor_user_id,
		action_date,
		description,
		reply_to_history_id,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'Comment',
		vr_user_id,
		vr_now,
		gfn_verify_string(vr_description),
		vr_reply_to_history_id,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	);
	-- end of create history
	
	
	-- Send new dashboards
	SELECT vr_creator_user_id = nd.creator_user_id
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	LIMIT 1;
	
	SELECT 	vr_username = un.username, 
			vr_first_name = un.first_name, 
			vr_last_name = un.last_name
	FROM users_normal AS un
	WHERE un.application_id = vr_application_id AND un.user_id = vr_user_id
	LIMIT 1;
	
	DROP TABLE IF EXISTS vr_dash_63922;
	
	CREATE TEMP TABLE vr_dash_63922 OF dashboard_table_type;
	
	INSERT INTO vr_dash_63922 (
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
			'KnowledgeComment',
			TRUE,
			vr_now,
			'{"UserID":"' || vr_user_id::VARCHAR(50) || '"' ||
				',"UserName":"' || gfn_base64_encode(vr_username) || '"' ||
				',"FirstName":"' || gfn_base64_encode(vr_first_name) || '"' ||
				',"LastName":"' || gfn_base64_encode(vr_last_name) || '"' ||
			'}'
	FROM UNNEST(vr_audience_user_ids) AS rf;
	
	vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
		SELECT d
		FROM vr_dash_63922 AS d
	));
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	ELSE
		RETURN QUERY
		SELECT d.*
		FROM vr_dash_63922 AS d;
	END IF;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

