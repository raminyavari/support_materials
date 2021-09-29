DROP FUNCTION IF EXISTS dct_arithmetic_delete_tree_node;

CREATE OR REPLACE FUNCTION dct_arithmetic_delete_tree_node
(
	vr_application_id	UUID,
    vr_tree_node_ids	guid_table_type[],
    vr_tree_owner_id	UUID,
	vr_remove_hierarchy BOOLEAN,
    vr_current_user_id	UUID,
    vr_now			 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE 
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_tree_node_ids) AS x
	);
	
	RETURN dct_p_remove_tree_nodes(vr_application_id, vr_ids, vr_tree_owner_id, 
								   vr_remove_hierarchy, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;
