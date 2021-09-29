DROP FUNCTION IF EXISTS dct_is_private_tree;

CREATE OR REPLACE FUNCTION dct_is_private_tree
(
	vr_application_id			UUID,
	vr_tree_id_or_tree_node_id	UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		WHERE EXISTS(
				SELECT tr.tree_id
				FROM dct_trees AS tr
				WHERE tr.application_id = vr_application_id AND 
					tr.tree_id = vr_tree_id_or_tree_node_id AND tr.is_private = TRUE
				LIMIT 1
			) OR EXISTS(
				SELECT n.tree_node_id
				FROM dct_tree_nodes AS n
					INNER JOIN dct_trees AS tr
					ON tr.application_id = vr_application_id AND tr.tree_id = n.tree_id
				WHERE n.application_id = vr_application_id AND 
					n.tree_node_id = vr_tree_id_or_tree_node_id AND tr.is_private = TRUE
				LIMIT 1
			)
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;
