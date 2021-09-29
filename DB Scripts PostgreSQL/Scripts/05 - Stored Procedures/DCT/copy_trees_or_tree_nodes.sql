DROP FUNCTION IF EXISTS dct_copy_trees_or_tree_nodes;

CREATE OR REPLACE FUNCTION dct_copy_trees_or_tree_nodes
(
	vr_application_id			UUID,
    vr_tree_id_or_tree_node_id	UUID,
    vr_copied_ids				guid_table_type[],
    vr_current_user_id			UUID,
    vr_now			 			TIMESTAMP
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_cp_ids		UUID[];
	vr_tree_id 		UUID;
	vr_tree_node_id UUID;
	vr_root_seq 	INTEGER;
BEGIN
	vr_cp_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_copied_ids) AS x
	);

	DROP TABLE IF EXISTS tbl_04823;

	CREATE TEMP TABLE tbl_04823 (
		"id" 		UUID, 
		"name" 		VARCHAR, 
		parent_id	UUID, 
		new_id 		UUID, 
		"level" 	INTEGER, 
		seq 		INTEGER
	);
	
	INSERT INTO tbl_04823 ("id", "name", parent_id, new_id, "level", seq)
	SELECT rf.node_id, rf.name, rf.parent_id, gen_random_uuid(), rf.level, rf.sequence_number
	FROM dct_fn_get_child_nodes_hierarchy(vr_application_id, vr_cp_ids, FALSE) AS rf;
	
	SELECT vr_tree_id = "t".tree_id
	FROM dct_trees AS "t"
	WHERE "t".application_id = vr_application_id AND "t".tree_id = vr_tree_id_or_tree_node_id;
	
	SELECT 	vr_tree_id = tn.tree_id, 
			vr_tree_node_id = tn.tree_node_id
	FROM dct_tree_nodes AS tn
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_id_or_tree_node_id;
	
	IF vr_tree_id IS NULL THEN
		CALL gfn_raise_exception();
		RETURN;
	END IF;
	
	vr_root_seq := 1 + COALESCE((
		SELECT MAX(tn.sequence_number) + COUNT(tn.tree_node_id)
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND (
				(vr_tree_node_id IS NULL AND tn.parent_node_id IS NULL) OR
				tn.parent_node_id = vr_tree_node_id
			)
	), 0)::INTEGER;
	
	WITH "data" AS (
		SELECT	ROW_NUMBER() OVER(ORDER BY 
					COALESCE("t".sequence_number, 10000)::INTEGER ASC, 
					"t".name ASC,
					COALESCE(nd.seq, 10000)::INTEGER ASC,
					nd.name ASC,
					tn.creation_date ASC
				) AS "row_number",
				tn.tree_node_id
		FROM tbl_04823 AS nd
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND tn.tree_node_id = nd.id
			INNER JOIN dct_trees AS "t"
			ON "t".application_id = vr_application_id AND "t".tree_id = tn.tree_id
		WHERE nd.level = 0
	)
	UPDATE tbl_04823
	SET seq = rf.row_number + vr_root_seq
	FROM tbl_04823 AS x
		INNER JOIN "data" AS rf
		ON rf.tree_node_id = x.id;
	
	INSERT INTO dct_tree_nodes (
		application_id,
		tree_node_id,
		tree_id,
		"name",
		sequence_number,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT vr_application_id, "t".new_id, vr_tree_id, "t".name, "t".seq, vr_current_user_id, vr_now, FALSE
	FROM tbl_04823 AS "t";
	
	UPDATE dct_tree_nodes
	SET parent_node_id = CASE WHEN node.level = 0 THEN vr_tree_node_id ELSE parent.new_id END
	FROM tbl_04823 AS node
		LEFT JOIN tbl_04823 AS parent
		ON parent.id = node.parent_id
		INNER JOIN dct_tree_nodes AS tn
		ON tn.application_id = vr_application_id AND tn.tree_node_id = node.new_id;
	
	RETURN QUERY
    SELECT "t".new_id AS "id"
    FROM tbl_04823 AS "t"
    WHERE "t".level = 0;
END;
$$ LANGUAGE plpgsql;
