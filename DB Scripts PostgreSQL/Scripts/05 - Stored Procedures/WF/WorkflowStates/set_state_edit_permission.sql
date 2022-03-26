DROP FUNCTION IF EXISTS wf_set_state_edit_permission;

CREATE OR REPLACE FUNCTION wf_set_state_edit_permission
(
	vr_application_id	UUID,
    vr_workflow_id		UUID,
	vr_state_id			UUID,
	vr_edit_permission	BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_workflow_states AS s
	SET edit_permission = vr_edit_permission,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

