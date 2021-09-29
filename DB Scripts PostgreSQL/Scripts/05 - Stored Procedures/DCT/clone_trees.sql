DROP FUNCTION IF EXISTS dct_clone_trees;

CREATE OR REPLACE FUNCTION dct_clone_trees
(
	vr_application_id	UUID,
	vr_tree_ids			guid_table_type[],
	vr_owner_id			UUID,
	vr_allow_nultiple 	BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS SETOF dct_tree_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	DROP TABLE IF EXISTS tree_34435;
	DROP TABLE IF EXISTS tree_node_34853;

	CREATE TEMP TABLE tree_34435 (
		tree_id 		UUID, 
		tree_id_new 	UUID,
		already_created BOOLEAN,
		seq 			INTEGER
	);

	CREATE TEMP TABLE tree_node_34853 (
		tree_id 		UUID, 
		"id" 			UUID, 
		parent_id 		UUID,
		tree_id_new 	UUID, 
		id_new 			UUID, 
		parent_id_new	UUID
	);

	INSERT INTO tree_34435 (tree_id, tree_id_new, already_created, seq)
	SELECT	x.value, 
			COALESCE(tr.tree_id, gen_random_uuid()), 
			CASE WHEN tr.tree_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN,
			x.seq
	FROM UNNEST(vr_tree_ids) WITH ORDINALITY AS x(vlaue, seq)
		LEFT JOIN dct_trees AS tr
		ON tr.application_id = vr_application_id AND tr.owner_id = vr_owner_id AND 
			tr.ref_tree_id = x.value AND COALESCE(vr_allow_multiple, FALSE) = FALSE;

	INSERT INTO dct_trees (
		application_id,
		tree_id,
		ref_tree_id,
		is_private,
		owner_id,
		"name",
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT	tr.application_id, 
			rf.tree_id_new, 
			rf.tree_id, 
			CASE WHEN vr_owner_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN, 
			vr_owner_id, 
			tr.name, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM tree_34435 AS rf
		INNER JOIN dct_trees AS tr
		ON tr.application_id = vr_application_id AND tr.tree_id = rf.tree_id
	WHERE rf.already_created = FALSE;
		
	INSERT INTO tree_node_34853 (tree_id, "id", parent_id, tree_id_new, id_new)
	SELECT n.tree_id, n.tree_node_id, n.parent_node_id, rf.tree_id_new, gen_random_uuid()
	FROM tree_34435 AS rf
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND 
			n.tree_id = rf.tree_id AND n.deleted = FALSE
	WHERE rf.already_created = FALSE;

	WITH "data" AS (
		SELECT "p".tree_id, "p".id
		FROM tree_node_34853 AS "t"
			INNER JOIN tree_node_34853 AS "p"
			ON "p".tree_id = "t".tree_id AND "p".id = "t".parent_id
	)
	UPDATE tree_node_34853
	SET parent_id_new = "p".id_new
	FROM tree_node_34853 AS "t"
		INNER JOIN "data" AS d
		ON d.tree_id = "t".tree_id AND d.id = "t".parent_id;

	INSERT INTO dct_tree_nodes (
		application_id,
		tree_node_id,
		tree_id,
		"name",
		creator_user_id,
		creation_date,
		sequence_number,
		deleted
	)
	SELECT vr_application_id, tn.id_new, tn.tree_id_new, 
		n.name, vr_current_user_id, vr_now, n.sequence_number, FALSE
	FROM tree_node_34853 AS tn
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND n.tree_node_id = tn.id;

	UPDATE dct_tree_nodes
	SET parent_node_id = tr.parent_id_new
	FROM tree_node_34853 AS tr
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND n.tree_node_id = tr.id_new
	WHERE tr.parent_id_new IS NOT NULL AND tr.id_new <> tr.parent_id_new;

	vr_ids := ARRAY(
		SELECT tr.tree_id_new
		FROM tree_34435 AS tr
	);

	RETURN QUERY
	SELECT *
	FROM dct_p_get_trees_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
