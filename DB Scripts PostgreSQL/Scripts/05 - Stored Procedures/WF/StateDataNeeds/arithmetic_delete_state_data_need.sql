DROP FUNCTION IF EXISTS wf_arithmetic_delete_state_data_need;

CREATE OR REPLACE FUNCTION wf_arithmetic_delete_state_data_need
(
	vr_application_id	UUID,
    vr_workflow_id		UUID,
	vr_state_id			UUID,
	vr_node_type_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_state_data_needs AS d
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE d.application_id = vr_application_id AND d.workflow_id = vr_workflow_id AND 
		d.state_id = vr_state_id AND d.node_type_id = vr_node_type_id AND d.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

