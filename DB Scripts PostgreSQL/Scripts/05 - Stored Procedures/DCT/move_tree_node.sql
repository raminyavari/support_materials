DROP FUNCTION IF EXISTS dct_move_tree_node;

CREATE OR REPLACE FUNCTION dct_move_tree_node
(
	vr_application_id			UUID,
    vr_tree_node_ids			guid_table_type[],
    vr_new_parent_node_id		UUID,
    vr_current_user_id			UUID,
    vr_now			 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 	INTEGER;
BEGIN
	IF vr_new_parent_node_id IS NOT NULL AND EXISTS(
		SELECT 1
		FROM dct_p_get_tree_node_hierarchy(vr_application_id, vr_new_parent_node_id) AS "p"
			INNER JOIN UNNEST(vr_tree_node_ids) AS n
			ON n.value = "p".node_id
		LIMIT 1
	) THEN
		CALL gfn_raise_exception(-1, 'CannotTransferToChilds');
		RETURN -1;
	END IF;
	
	UPDATE dct_tree_nodes
	SET parent_node_id = vr_new_parent_node_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_tree_node_ids) AS rf
		INNER JOIN dct_tree_nodes AS tn
		ON tn.tree_node_id = rf.value
	WHERE tn.application_id = vr_application_id AND 
		(vr_new_parent_node_id IS NULL OR tn.tree_node_id <> vr_new_parent_node_id);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
