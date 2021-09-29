DROP FUNCTION IF EXISTS dct_get_tree_owner_id;

CREATE OR REPLACE FUNCTION dct_get_tree_owner_id
(
	vr_application_id			UUID,
	vr_tree_id_or_tree_node_id	UUID
)
RETURNS UUID
AS
$$
BEGIN
	vr_tree_id_or_tree_node_id = COALESCE((
		SELECT tn.tree_id
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_id_or_tree_node_id
		LIMIT 1
	), vr_tree_id_or_tree_node_id);
	
	RETURN (
		SELECT tr.owner_id AS "id"
		FROM dct_trees AS tr
		WHERE tr.tree_id = vr_tree_id_or_tree_node_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;
