DROP FUNCTION IF EXISTS wf_get_workflow_items_count;

CREATE OR REPLACE FUNCTION wf_get_workflow_items_count
(
	vr_application_id	UUID,
	vr_workflow_id		UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN ((
		SELECT COUNT(DISTINCT h.owner_id)
		FROM wf_history AS h
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = h.owner_id AND nd.deleted = FALSE
		WHERE h.application_id = vr_application_id AND h.workflow_id = vr_workflow_id AND h.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

