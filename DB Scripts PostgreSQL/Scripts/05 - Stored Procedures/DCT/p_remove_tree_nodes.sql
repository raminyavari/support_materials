DROP FUNCTION IF EXISTS dct_p_remove_tree_nodes;

CREATE OR REPLACE FUNCTION dct_p_remove_tree_nodes
(
	vr_application_id	UUID,
    vr_tree_node_ids	UUID[],
    vr_tree_owner_id	UUID,
	vr_remove_hierarchy BOOLEAN,
    vr_current_user_id	UUID,
    vr_now			 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 	INTEGER;
	vr_result2 	INTEGER;
BEGIN
	IF COALESCE(vr_remove_hierarchy, FALSE) = FALSE THEN
		UPDATE dct_tree_nodes
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM UNNEST(vr_tree_node_ids) AS x
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND 
				tn.tree_node_id = x AND tn.deleted = FALSE
			INNER JOIN dct_trees AS "t"
			ON "t".application_id = vr_application_id AND "t".tree_id = tn.tree_id AND
				((vr_tree_owner_id IS NULL AND "t".owner_id IS NULL) OR "t".owner_id = vr_tree_owner_id);
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		UPDATE dct_tree_nodes
		SET parent_node_id = NULL,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM dct_tree_nodes AS tn
			INNER JOIN dct_trees AS "t"
			ON "t".application_id = vr_application_id AND "t".tree_id = tn.tree_id AND
				((vr_tree_owner_id IS NULL AND "t".owner_id IS NULL) OR "t".owner_id = vr_tree_owner_id)
		WHERE tn.application_id = vr_application_id AND 
			tn.parent_node_id IN (SELECT UNNEST(vr_tree_node_ids)) AND tn.deleted = FALSE;
		
		GET DIAGNOSTICS vr_result2 := ROW_COUNT;
		
		RETURN (CASE WHEN vr_result2 > vr_result THEN vr_result2 ELSE vr_result END);
	ELSE
		UPDATE dct_tree_nodes
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM dct_fn_get_child_nodes_hierarchy(vr_application_id, vr_tree_node_ids, FALSE) AS rf
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND 
				tn.tree_node_id = rf.node_id AND tn.deleted = FALSE
			INNER JOIN dct_trees AS "t"
			ON "t".application_id = vr_application_id AND "t".tree_id = tn.tree_id AND
				((vr_tree_owner_id IS NULL AND "t".owner_id IS NULL) OR "t".owner_id = vr_tree_owner_id);
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
			
		RETURN vr_result;
	END IF;
END;
$$ LANGUAGE plpgsql;
