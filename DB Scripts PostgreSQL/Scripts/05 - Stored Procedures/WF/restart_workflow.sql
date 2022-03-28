DROP FUNCTION IF EXISTS wf_restart_workflow;

CREATE OR REPLACE FUNCTION wf_restart_workflow
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_director_node_id	UUID,
	vr_director_user_id	UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_workflow_id	UUID;
	vr_result 		INTEGER;
	vr_message 		VARCHAR;
	vr_cur_result	REFCURSOR;
	vr_cur_dash		REFCURSOR;
BEGIN
	SELECT 	h.workflow_id
	INTO	vr_workflow_id
	FROM wf_history AS h
	WHERE h.application_id = vr_application_id AND h.owner_id = vr_owner_id
	ORDER BY h.id DESC
	LIMIT 1;
	
	IF vr_workflow_id IS NULL THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'WorkFlowNotFound');
	ELSE
		SELECT 	x.result,
				x.message,
				x.dashboards
		INTO	vr_result,
				vr_message,
				vr_cur_dash
		FROM wf_p_start_new_workflow(vr_application_id, vr_owner_id, vr_workflow_id, vr_director_node_id,
									 vr_director_user_id, vr_current_user_id, vr_now) AS x;
	
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(vr_result, vr_message);
			RETURN;
		END IF;
		
		OPEN vr_cur_result FOR
		SELECT 1::INTEGER;
		
		RETURN NEXT vr_cur_dash;
		RETURN NEXT vr_cur_result;
	END IF;
END;
$$ LANGUAGE plpgsql;

