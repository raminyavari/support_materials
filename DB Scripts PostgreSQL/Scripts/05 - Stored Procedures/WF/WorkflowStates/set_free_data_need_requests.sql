DROP FUNCTION IF EXISTS wf_set_free_data_need_requests;

CREATE OR REPLACE FUNCTION wf_set_free_data_need_requests
(
	vr_application_id			UUID,
    vr_workflow_id				UUID,
	vr_state_id					UUID,
	vr_free_data_need_requests	BOOLEAN,
	vr_current_user_id			UUID,
	vr_now		 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_workflow_states AS s
	SET free_data_need_requests = vr_free_data_need_requests,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

