DROP FUNCTION IF EXISTS dct_p_add_tree_node_contents;

CREATE OR REPLACE FUNCTION dct_p_add_tree_node_contents
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_node_ids			UUID[],
	vr_remove_from		UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	IF vr_remove_from IS NOT NULL AND vr_remove_from <> vr_tree_node_id THEN
		UPDATE dct_tree_node_contents
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM UNNEST(vr_node_ids) AS x
			INNER JOIN dct_tree_node_contents AS tc
			ON tc.application_id = vr_application_id AND 
				tc.tree_node_id = vr_remove_from AND tc.node_id = x AND tc.deleted = FALSE;
	END IF;
	
	UPDATE dct_tree_node_contents
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_ids) AS x
		INNER JOIN dct_tree_node_contents AS tc
		ON tc.application_id = vr_application_id AND 
			tc.tree_node_id = vr_tree_node_id AND tc.node_id = x;
			
	INSERT INTO dct_tree_node_contents (
		application_id,
		tree_node_id,
		node_id,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT vr_application_id, vr_tree_node_id, x, vr_current_user_id, vr_now, FALSE
	FROM UNNEST(vr_node_ids) AS x
		LEFT JOIN dct_tree_node_contents AS tc
		ON tc.application_id = vr_application_id AND 
			tc.tree_node_id = vr_tree_node_id AND tc.node_id = x
	WHERE tc.tree_node_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;
