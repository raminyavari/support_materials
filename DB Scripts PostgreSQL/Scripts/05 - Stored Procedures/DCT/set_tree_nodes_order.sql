DROP FUNCTION IF EXISTS dct_set_tree_nodes_order;

CREATE OR REPLACE FUNCTION dct_set_tree_nodes_order
(
	vr_application_id	UUID,
	vr_tree_node_ids	guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_tn_id			UUID;
	vr_parent_node_id 	UUID;
	vr_tree_id 			UUID;
	vr_ids				UUID;
	vr_result			INTEGER;
BEGIN
	SELECT vr_tn_id = rf.value
	FROM UNNEST(vr_tree_node_ids) AS rf
	LIMIT 1;

	SELECT 	vr_parent_node_id = tn.parent_node_id, 
			vr_tree_id = tn.tree_id
	FROM dct_tree_nodes AS tn
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tn_id
	LIMIT 1;
	
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_tree_node_ids) AS x
		
		UNION ALL
		
		SELECT tn.tree_node_id
		FROM UNNEST(vr_tree_node_ids) AS x
			RIGHT JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND tn.tree_node_id = x.value
		WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND (
				(tn.parent_node_id IS NULL AND vr_parent_node_id IS NULL) OR 
				tn.parent_node_id = vr_parent_node_id
			) AND x.value IS NULL
		ORDER BY tn.sequence_number ASC
	);
	
	UPDATE dct_tree_nodes
	SET sequence_number = x.seq
	FROM UNNEST(vr_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN dct_tree_nodes AS tn
		ON tn.tree_node_id = x.id
	WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND (
			(tn.parent_node_id IS NULL AND vr_parent_node_id IS NULL) OR 
			tn.parent_node_id = vr_parent_node_id
		);
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
