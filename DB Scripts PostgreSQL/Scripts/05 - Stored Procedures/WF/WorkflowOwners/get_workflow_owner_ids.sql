DROP FUNCTION IF EXISTS wf_get_workflow_owner_ids;

CREATE OR REPLACE FUNCTION wf_get_workflow_owner_ids
(
	vr_application_id	UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT DISTINCT o.node_type_id AS "id"
	FROM wf_workflow_owners AS o
	WHERE o.application_id = vr_application_id AND o.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

