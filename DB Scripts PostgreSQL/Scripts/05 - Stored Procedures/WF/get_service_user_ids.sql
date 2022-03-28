DROP FUNCTION IF EXISTS wf_get_service_user_ids;

CREATE OR REPLACE FUNCTION wf_get_service_user_ids
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_node_type_id		UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT DISTINCT nc.user_id AS "id"
	FROM
		(
			SELECT DISTINCT h.owner_id
			FROM wf_history AS h
			WHERE h.application_id = vr_application_id AND 
				(vr_workflow_id IS NULL OR h.workflow_id = vr_workflow_id) AND h.deleted = FALSE
		) AS nds
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nds.owner_id
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = nds.owner_id
	WHERE (vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
		nd.deleted = FALSE AND nc.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

