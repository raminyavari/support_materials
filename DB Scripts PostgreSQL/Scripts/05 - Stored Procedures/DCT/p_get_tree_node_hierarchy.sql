DROP FUNCTION IF EXISTS dct_p_get_tree_node_hierarchy;

CREATE OR REPLACE FUNCTION dct_p_get_tree_node_hierarchy
(
	vr_application_id	UUID,
    vr_tree_node_id 	UUID
)
RETURNS TABLE (
	"id"		UUID, 
	parent_id	UUID, 
	"level"		INTEGER, 
	"name"		VARCHAR
)
AS
$$
DECLARE
	vr_tree_id	UUID;
BEGIN
	SELECT vr_tree_id = tn.tree_id 
	FROM dct_tree_nodes AS tn
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_node_id
	LIMIT 1;
 	
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", parent_id, "level", "name")
 	AS 
	(
		SELECT tn.tree_node_id AS "id", parent_node_id AS parent_id, 0::INTEGER AS "level", tn.name
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_node_id
		
		UNION ALL
		
		SELECT node.tree_node_id AS id, node.parent_node_id AS parent_id, hr.level + 1, node.name
		FROM dct_tree_nodes AS node
			INNER JOIN "hierarchy" AS hr
			ON node.tree_node_id = hr.parent_id
		WHERE node.application_id = vr_application_id AND 
			node.tree_id = vr_tree_id AND node.tree_node_id <> hr.id AND node.deleted = FALSE
	)
	SELECT * 
	FROM "hierarchy"
	ORDER BY "hierarchy".level ASC;
END;
$$ LANGUAGE plpgsql;
