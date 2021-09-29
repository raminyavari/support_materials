DROP FUNCTION IF EXISTS dct_get_tree_nodes_by_ids;

CREATE OR REPLACE FUNCTION dct_get_tree_nodes_by_ids
(
	vr_application_id	UUID,
    vr_tree_node_ids	guid_table_type[]
)
RETURNS SETOF dct_tree_node_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_tree_node_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM dct_p_get_tree_nodes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
