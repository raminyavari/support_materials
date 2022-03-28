DROP FUNCTION IF EXISTS wf_arithmetic_delete_owner_workflow;

CREATE OR REPLACE FUNCTION wf_arithmetic_delete_owner_workflow
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_workflow_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_workflow_owners AS o
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE o.application_id = vr_application_id AND
		o.node_type_id = vr_node_type_id AND o.workflow_id = vr_workflow_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

