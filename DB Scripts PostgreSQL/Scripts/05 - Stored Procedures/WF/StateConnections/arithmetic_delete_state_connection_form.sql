DROP FUNCTION IF EXISTS wf_arithmetic_delete_state_connection_form;

CREATE OR REPLACE FUNCTION wf_arithmetic_delete_state_connection_form
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_id		UUID,
	vr_out_state_id		UUID,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_state_connection_forms AS f
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE f.application_id = vr_application_id AND f.workflow_id = vr_workflow_id AND 
		f.in_state_id = vr_in_state_id AND f.out_state_id = vr_out_state_id AND 
		f.form_id = vr_form_id AND f.deleted = FALSE;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

