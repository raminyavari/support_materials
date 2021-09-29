DROP FUNCTION IF EXISTS dct_p_get_tree_nodes_by_ids;

CREATE OR REPLACE FUNCTION dct_p_get_tree_nodes_by_ids
(
	vr_application_id	UUID,
    vr_tree_node_ids	UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF dct_tree_node_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT tn.tree_node_id,
		   tn.tree_id,
		   tn.parent_node_id,
		   tn.name,
		   COALESCE((
				SELECT TRUE 
				FROM dct_tree_nodes AS "t"
				WHERE "t".application_id = vr_application_id AND 
					"t".parent_node_id = x.id AND "t".deleted = FALSE
				LIMIT 1
			), FALSE)::BOOLEAN AS has_child,
			vr_total_count
	FROM UNNEST(vr_tree_node_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN dct_tree_nodes AS tn
		ON tn.tree_node_id = x.id
	WHERE tn.application_id = vr_application_id AND tn.deleted = FALSE
	ORDER BY x.seq ASC;
END;
$$ LANGUAGE plpgsql;
