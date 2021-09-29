DROP FUNCTION IF EXISTS dct_p_remove_tree_node_contents;

CREATE OR REPLACE FUNCTION dct_p_remove_tree_node_contents
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_node_ids			UUID[],
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_tree_node_contents
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_ids) AS ex
		INNER JOIN dct_tree_node_contents AS tc
		ON tc.application_id = vr_application_id AND 
			tc.tree_node_id = vr_tree_node_id AND tc.node_id = ex.value;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
