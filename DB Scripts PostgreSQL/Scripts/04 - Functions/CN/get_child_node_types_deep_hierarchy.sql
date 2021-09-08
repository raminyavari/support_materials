DROP FUNCTION IF EXISTS cn_fn_get_child_node_types_deep_hierarchy;

CREATE OR REPLACE FUNCTION cn_fn_get_child_node_types_deep_hierarchy
(
	vr_application_id	UUID,
	vr_node_type_ids	UUID[]
)
RETURNS TABLE (
	node_type_id	UUID,
	parent_id 		UUID,
	"level" 		INTEGER,
	"name" 			VARCHAR(2000)
)
AS
$$
BEGIN
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", parent_id, "level", "name")
 	AS 
	(
		SELECT nd.node_type_id AS "id", nd.parent_id, 0::INTEGER AS "level", nd.name
		FROM UNNEST(vr_node_type_ids) AS n
			INNER JOIN cn_node_types AS nd
			ON nd.application_id = vr_application_id AND nd.node_type_id = n
		
		UNION ALL
		
		SELECT nt.node_type_id AS "id", nt.parent_id, hr."level" + 1, nt.name
		FROM cn_node_types AS nt
			INNER JOIN "hierarchy" AS hr
			ON hr.id = nt.parent_id
		WHERE nt.application_id = vr_application_id AND nt.node_type_id <> hr.id AND nt.deleted = FALSE
	)
	SELECT *
	FROM (
			SELECT	h.id, 
					MAX(h.parent_id::VARCHAR(50))::UUID AS parent_id, 
					MIN(h.level) AS "level", 
					MAX(h.name) AS "name"
			FROM "hierarchy" AS h
			GROUP BY h.id
		) AS x
	ORDER BY x.level ASC;
END;
$$ LANGUAGE PLPGSQL;