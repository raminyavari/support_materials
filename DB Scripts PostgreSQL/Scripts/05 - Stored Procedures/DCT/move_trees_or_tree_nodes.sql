DROP FUNCTION IF EXISTS dct_move_trees_or_tree_nodes;

CREATE OR REPLACE FUNCTION dct_move_trees_or_tree_nodes
(
	vr_application_id			UUID,
    vr_tree_id_or_tree_node_id	UUID,
    vr_moved_ids				guid_table_type[],
    vr_current_user_id			UUID,
    vr_now			 			TIMESTAMP
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_mv_ids		UUID[];
	vr_tree_id 		UUID;
	vr_tree_node_id UUID;
	vr_root_seq 	INTEGER;
BEGIN
	vr_mv_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_moved_ids) AS x
	);
	
	IF EXISTS(
		SELECT 1
		FROM UNNEST(vr_mv_ids) AS "m"
		WHERE "m" = vr_tree_id_or_tree_node_id
		LIMIT 1
	) THEN
		CALL gfn_raise_exception(-1, 'CannotTransferToChilds');
		RETURN;
	END IF;
	
	DROP TABLE IF EXISTS tbl_34924;
	
	CREATE TEMP TABLE tbl_34924 (
		"id" 		UUID, 
		"name" 		VARCHAR, 
		parent_id 	UUID, 
		"level" 	INTEGER, 
		seq 		INTEGER
	);
	
	INSERT INTO tbl_34924 ("id", "name", parent_id, "level", seq)
	SELECT rf.node_id, rf.name, rf.parent_id, rf.level, rf.sequence_number
	FROM dct_fn_get_child_nodes_hierarchy(vr_application_id, vr_mv_ids, NULL) AS rf;
	
	IF EXISTS(
		SELECT 1
		FROM tbl_34924 AS "t"
		WHERE "t".id = vr_tree_id_or_tree_node_id
		LIMIT 1
	) THEN
		CALL gfn_raise_exception(-1, 'CannotTransferToChilds');
		RETURN;
	END IF;
	
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
		FROM tbl_34924 AS nd
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND tn.tree_node_id = nd.id
			INNER JOIN dct_trees AS "t"
			ON "t".application_id = vr_application_id AND "t".tree_id = tn.tree_id
		WHERE nd.level = 0
	)
	UPDATE tbl_34924
	SET seq = rf.row_number + vr_root_seq
	FROM tbl_34924 AS x
		INNER JOIN "data" AS rf
		ON rf.tree_node_id = x.id;
	
	UPDATE dct_tree_nodes
	SET tree_id = vr_tree_id,
		parent_node_id = CASE WHEN node.level = 0 THEN vr_tree_node_id ELSE tn.parent_node_id END,
		sequence_number = CASE WHEN node.level = 0 THEN node.seq ELSE tn.sequence_number END,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM tbl_34924 AS node
		INNER JOIN dct_tree_nodes AS tn
		ON tn.application_id = vr_application_id AND tn.tree_node_id = node.id;
		
	UPDATE dct_trees
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_mv_ids) AS x
		INNER JOIN dct_trees AS "t"
		ON "t".application_id = vr_application_id AND "t".tree_id = x;
	
	RETURN QUERY
    SELECT "t".id AS "id"
    FROM tbl_34924 AS "t"
    WHERE "t".level = 0;
END;
$$ LANGUAGE plpgsql;
