DROP FUNCTION IF EXISTS wf_get_owner_workflows;

CREATE OR REPLACE FUNCTION wf_get_owner_workflows
(
	vr_application_id	UUID,
	vr_node_type_id		UUID
)
RETURNS SETOF wf_workflow_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM wf_p_get_workflows_by_ids(
		vr_application_id, 
		ARRAY(
			SELECT o.workflow_id
			FROM wf_workflow_owners AS o
			WHERE o.application_id = vr_application_id AND 
				o.node_type_id = vr_node_type_id AND o.deleted = FALSE
		)
	);
END;
$$ LANGUAGE plpgsql;

