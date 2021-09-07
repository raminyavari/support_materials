DROP FUNCTION IF EXISTS dct_fn_get_child_nodes_deep_hierarchy;

CREATE OR REPLACE FUNCTION dct_fn_get_child_nodes_deep_hierarchy
(
	vr_application_id	UUID,
	vr_node_ids			UUID[]
)
RETURNS TABLE (
	node_id 		UUID,
	parent_id		UUID,
	"level" 		INTEGER,
	"name"			VARCHAR(2000),
	sequence_number	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH RECURSIVE "hierarchy"
 	AS 
	(
		SELECT tn.tree_node_id AS "id", tn.parent_node_id AS parent_id, 0::INTEGER AS "level", tn.name AS "name"
		FROM UNNEST(vr_node_ids) AS n
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND tn.tree_node_id = n
		
		UNION ALL
		
		SELECT node.tree_node_id AS "id", node.parent_node_id AS parent_id, "level" + 1, node.name
		FROM dct_tree_nodes AS node
			INNER JOIN "hierarchy" AS hr
			ON hr.id = node.parent_node_id
		WHERE node.application_id = vr_application_id AND 
			node.tree_node_id <> hr.id AND node.deleted = FALSE
	)
	SELECT h.id, h.parent_id, h.level, h.name
	FROM "hierarchy" AS h
	ORDER BY h.level ASC;
END;
$$ LANGUAGE PLPGSQL;