DROP FUNCTION IF EXISTS dct_get_root_nodes;

CREATE OR REPLACE FUNCTION dct_get_root_nodes
(
	vr_application_id	UUID,
    vr_tree_id			UUID
)
RETURNS SETOF dct_tree_node_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT tn.tree_node_id
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND deleted = FALSE AND
			(tn.parent_node_id IS NULL OR tn.parent_node_id = tn.tree_node_id)
		ORDER BY COALESCE(tn.sequence_number, 100000) ASC, tn.name ASC, tn.creation_date ASC
	);

	RETURN QUERY
	SELECT *
	FROM dct_p_get_tree_nodes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
