DROP FUNCTION IF EXISTS wf_get_owner_workflow_primary_key;

CREATE OR REPLACE FUNCTION wf_get_owner_workflow_primary_key
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_workflow_id		UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT o.id
	FROM wf_workflow_owners AS o
	WHERE o.application_id = vr_application_id AND 
		o.node_type_id = vr_node_type_id AND o.workflow_id = vr_workflow_id;
END;
$$ LANGUAGE plpgsql;

