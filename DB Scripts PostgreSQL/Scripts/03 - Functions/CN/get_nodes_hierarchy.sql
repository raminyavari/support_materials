DROP FUNCTION IF EXISTS cn_fn_get_nodes_hierarchy;

CREATE OR REPLACE FUNCTION cn_fn_get_nodes_hierarchy
(
	vr_application_id	UUID,
	vr_node_ids			UUID[]
)
RETURNS TABLE (
	node_id 	UUID,
	parent_id	UUID,
	"level" 	INTEGER,
	"name"	 	VARCHAR(2000)
)
AS
$$
BEGIN
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", type_id, parent_id, "level", "name")
	AS 
	(
		SELECT nd.node_id AS "id", nd.node_type_id AS type_id, nd.parent_node_id AS parent_id, 0 AS "level", nd.name
		FROM UNNEST(vr_node_ids) AS n
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = n
		
		UNION ALL
		
		SELECT node.node_id AS "id", node.node_type_id, node.parent_node_id AS parent_id, "level" + 1, node.name
		FROM cn_nodes AS node
			INNER JOIN "hierarchy" AS hr
			ON hr.parent_id = node.node_id
		WHERE node.applicationID = vr_application_id AND node.node_type_id = hr.type_id AND
			node.node_id <> hr.id AND node.deleted = FALSE
	)
	SELECT h.id, h.parent_id, h.level, h.name
	FROM "hierarchy" AS h
	ORDER BY h.level ASC;
END;
$$ LANGUAGE PLPGSQL;