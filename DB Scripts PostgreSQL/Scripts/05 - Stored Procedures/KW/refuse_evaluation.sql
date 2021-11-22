DROP FUNCTION IF EXISTS kw_refuse_evaluation;

CREATE OR REPLACE FUNCTION kw_refuse_evaluation
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
	vr_now			 	TIMESTAMP,
    vr_admin_user_ids	guid_table_type[],
    vr_description	 	VARCHAR(2000)
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_username 	VARCHAR(1000);
	vr_first_name 	VARCHAR(1000);
	vr_last_name 	VARCHAR(1000);
	vr_result		INTEGER;
BEGIN
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		actor_user_id,
		action_date,
		description,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'RefuseEvaluation',
		vr_user_id,
		vr_now,
		vr_description,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	);
	-- end of create history
	
	
	-- Remove old dashboards
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, vr_user_id, 
													 vr_node_id, NULL, 'Knowledge', 'Evaluator');
		
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of remove old dashboards
	
	
	-- Send new dashboards
	SELECT 	vr_username = un.username, 
			vr_first_name = un.first_name, 
			vr_last_name = un.last_name
	FROM users_normal AS un
	WHERE un.application_id = vr_application_id AND un.user_id = vr_user_id;
	
	DROP TABLE IF EXISTS vr_dash_73452;
	
	CREATE TEMP TABLE vr_dash_73452 OF dashboard_table_type;
	
	INSERT INTO vr_dash_73452 (
		user_id, 
		node_id, 
		ref_item_id, 
		"type", 
		sub_type, 
		removable, 
		send_date, 
		"info"
	)
	SELECT	x.value,
			vr_node_id,
			vr_node_id,
			'Knowledge',
			'EvaluationRefused',
			TRUE,
			vr_now,
			'{"UserID":"' || vr_user_id::VARCHAR(50) || '"' ||
				',"UserName":"' || gfn_base64_encode(vr_username) || '"' ||
				',"FirstName":"' || gfn_base64_encode(vr_first_name) || '"' ||
				',"LastName":"' || gfn_base64_encode(vr_last_name) || '"' ||
			'}'
	FROM UNNEST(vr_admin_user_ids) AS x;
	
	vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
		SELECT d
		FROM vr_dash_73452 AS d
	));
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	ELSE
		RETURN QUERY
		SELECT d.*
		FROM vr_dash_73452 AS d;
	END IF;
	-- end of send new dashboards
END;
$$ LANGUAGE plpgsql;

