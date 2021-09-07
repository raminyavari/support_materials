DROP FUNCTION IF EXISTS dct_fn_get_child_nodes_hierarchy;

CREATE OR REPLACE FUNCTION dct_fn_get_child_nodes_hierarchy
(
	vr_application_id		UUID,
	vr_node_ids_or_tree_ids	UUID[],
	vr_archive		 		BOOLEAN
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
	WITH output_table AS
	(
		SELECT DISTINCT 
			x.tree_node_id AS "id",
			x.parent_node_id AS parent_id,
			0::INTEGER AS "level",
			x.name,
			x.sequence_number
		FROM (
				SELECT	tn.*
				FROM UNNEST(vr_node_ids_or_tree_ids) AS n
					INNER JOIN dct_tree_nodes AS tn
					ON tn.application_id = vr_application_id AND tn.tree_node_id = n

				UNION ALL

				SELECT tn.*
				FROM UNNEST(vr_node_ids_or_tree_ids) AS n
					INNER JOIN dct_trees AS "t"
					ON "t".application_id = vr_application_id AND "t".tree_id = n
					INNER JOIN dct_tree_nodes AS tn
					ON tn.application_id = vr_application_id AND 
						tn.tree_id = "t".tree_id AND tn.parent_node_id IS NULL AND 
						(vr_archive IS NULL OR tn.deleted = vr_archive)
			) AS x
	)
	SELECT *
	FROM output_table
	
	UNION ALL
	
	SELECT tn.tree_node_id AS "id", tn.parent_node_id AS parent_id, 
		ht.level + 1, tn.name AS "name", tn.sequence_number
	FROM dct_tree_nodes AS tn
		INNER JOIN output_table AS hr
		ON hr.node_id = tn.parent_node_id
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id <> hr.node_id AND 
		(vr_archive IS NULL OR tn.deleted = vr_archive);
END;
$$ LANGUAGE PLPGSQL;