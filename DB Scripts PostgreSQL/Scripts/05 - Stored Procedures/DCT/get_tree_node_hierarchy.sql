DROP FUNCTION IF EXISTS dct_get_tree_node_hierarchy;

CREATE OR REPLACE FUNCTION dct_get_tree_node_hierarchy
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID
)
RETURNS TABLE (
	"id"		UUID, 
	parent_id	UUID, 
	"level"		INTEGER, 
	"name"		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", parent_id, "level", "name")
	AS 
	(
		SELECT tn.tree_node_id AS "id", tn.parent_node_id, 0::INTEGER AS "level", tn.name
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_node_id
		
		UNION ALL
		
		SELECT tn.tree_node_id AS "id", tn.parent_node_id, hr.level + 1, tn.name
		FROM dct_tree_nodes AS tn
			INNER JOIN "hierarchy" AS hr
			ON tn.tree_node_id = hr.parent_id
		WHERE tn.application_id = vr_application_id AND tn.tree_node_id <> hr.id AND tn.deleted = FALSE
	)
	SELECT * 
	FROM "hierarchy";
END;
$$ LANGUAGE plpgsql;
