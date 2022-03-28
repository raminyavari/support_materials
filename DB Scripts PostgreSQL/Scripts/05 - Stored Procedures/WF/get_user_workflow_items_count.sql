DROP FUNCTION IF EXISTS wf_get_user_workflow_items_count;

CREATE OR REPLACE FUNCTION wf_get_user_workflow_items_count
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_date_from 		TIMESTAMP,
	vr_date_to 			TIMESTAMP
)
RETURNS TABLE (
	node_type_id	UUID,
	node_type		VARCHAR, 
	"count"			INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	counts.node_type_id,
		   	nt.name AS node_type, 
		   	counts.cnt AS "count"
	FROM (
			SELECT 	nd.node_type_id, 
					COUNT(nc.node_id) AS cnt
			FROM cn_node_creators AS nc
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
				INNER JOIN cn_services AS sr
				ON sr.application_id = vr_application_id AND sr.node_type_id = nd.node_type_id
			WHERE nc.application_id = vr_application_id AND nc.user_id = vr_user_id AND 
				EXISTS (
					SELECT 1
					FROM wf_history AS h
					WHERE h.application_id = vr_application_id AND 
						h.owner_id = nd.node_id AND h.deleted = FALSE
					LIMIT 1
				) AND nc.deleted = FALSE AND nd.deleted = FALSE AND
				(vr_date_from IS NULL OR nd.creation_date >= vr_date_from) AND
				(vr_date_to IS NULL OR nd.creation_date < vr_date_to)
			GROUP BY nd.node_type_id
		) AS counts
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = counts.node_type_id;
END;
$$ LANGUAGE plpgsql;

