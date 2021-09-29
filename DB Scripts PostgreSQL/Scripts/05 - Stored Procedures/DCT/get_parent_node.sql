DROP FUNCTION IF EXISTS dct_get_parent_node;

CREATE OR REPLACE FUNCTION dct_get_parent_node
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID
)
RETURNS SETOF dct_tree_node_ret_composite
AS
$$
DECLARE
	vr_ids			UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT "first".parent_node_id
		FROM dct_tree_nodes AS "first"
			INNER JOIN dct_tree_nodes AS "second"
			ON "second".application_id = vr_application_id AND 
				"second".tree_node_id = "first".parent_node_id
		WHERE "first".application_id = vr_application_id AND 
			"first".tree_node_id = vr_tree_node_id AND "second".deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM dct_p_get_tree_nodes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
