DROP FUNCTION IF EXISTS dct_get_trees_by_ids;

CREATE OR REPLACE FUNCTION dct_get_trees_by_ids
(
	vr_application_id	UUID,
    vr_tree_ids			guid_table_type[]
)
RETURNS SETOF dct_tree_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT COALESCE(n.tree_id, x.value)
		FROM UNNEST(vr_tree_ids) AS x
			LEFT JOIN dct_tree_nodes AS n
			ON n.application_id = vr_application_id AND n.tree_node_id = x.value
	);

	RETURN QUERY
	SELECT *
	FROM dct_p_get_trees_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
