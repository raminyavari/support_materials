DROP FUNCTION IF EXISTS wf_set_state_connection_label;

CREATE OR REPLACE FUNCTION wf_set_state_connection_label
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_id		UUID,
	vr_out_state_id		UUID,
	vr_label			VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_state_connections AS sc
	SET "label" = gfn_verify_string(vr_label),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
		sc.in_state_id = vr_in_state_id AND sc.out_state_id = vr_out_state_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

