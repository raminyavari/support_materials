DROP FUNCTION IF EXISTS dct_add_tree_node_contents;

CREATE OR REPLACE FUNCTION dct_add_tree_node_contents
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_node_ids			guid_table_type[],
	vr_remove_from		UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_node_ids) AS x
	);

	RETURN dct_p_add_tree_node_contents(vr_application_id, vr_tree_node_id, vr_ids, 
										vr_remove_from, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;
