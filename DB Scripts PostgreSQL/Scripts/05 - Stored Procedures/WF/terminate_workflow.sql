DROP FUNCTION IF EXISTS wf_terminate_workflow;

CREATE OR REPLACE FUNCTION wf_terminate_workflow
(
	vr_application_id	UUID,
	vr_prev_history_id	UUID,
    vr_description	 	VARCHAR(2000),
    vr_sender_user_id	UUID,
    vr_send_date		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_owner_id 	UUID;
	vr_workflow_id 	UUID;
	vr_result		INTEGER;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	
	SELECT 	h.owner_id, 
			h.workflow_id
	INTO 	vr_owner_id,
			vr_workflow_id
	FROM wf_history AS h
	WHERE h.application_id = vr_application_id AND h.history_id = vr_prev_history_id;
	
	UPDATE wf_history AS h
	SET terminated = TRUE,
		description = vr_description,
		actor_user_id = vr_sender_user_id
	WHERE h.application_id = vr_application_id AND h.history_id = vr_prev_history_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-6::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	-- Send Dashboards
	vr_result := ntfn_p_set_dashboards_as_done(vr_application_id, vr_sender_user_id, vr_owner_id, 
											   vr_prev_history_id, 'WorkFlow', NULL, vr_send_date);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'RemovingDashboardsFailed');
		RETURN -1::INTEGER;
	END IF;
	
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, 
													 vr_owner_id, NULL, 'WorkFlow', NULL);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'RemovingDashboardsFailed');
		RETURN -1::INTEGER;
	END IF;
	-- end of Send Dashboards
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

