DROP FUNCTION IF EXISTS dct_fn_get_parent_nodes_hierarchy;

CREATE OR REPLACE FUNCTION dct_fn_get_parent_nodes_hierarchy
(
	vr_application_id	UUID,
	vr_node_ids			UUID[]
)
RETURNS TABLE (
	node_id 		UUID,
	parent_id		UUID,
	"level" 		INTEGER,
	"name"			VARCHAR(2000)
)
AS
$$
BEGIN
	RETURN QUERY
	WITH tbl
	AS
	(
		SELECT	tn.tree_node_id AS "id", tn.parent_node_id AS parent_id, 0::INTEGER AS "level", tn.name
		FROM UNNEST(vr_node_ids) AS n
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND tn.tree_node_id = n
	)
	SELECT *
	FROM tbl
	
	UNION ALL
	
	SELECT tn.tree_node_id AS "id", tn.parent_node_id AS parent_id, "level" + 1, tn.name
	FROM dct_tree_nodes AS tn
		INNER JOIN tbl AS hr
		ON hr.parent_id = tn.tree_node_id
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id <> hr.node_id;
END;
$$ LANGUAGE PLPGSQL;