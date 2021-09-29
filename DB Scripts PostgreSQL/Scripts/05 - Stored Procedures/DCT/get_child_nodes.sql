DROP FUNCTION IF EXISTS dct_get_child_nodes;

CREATE OR REPLACE FUNCTION dct_get_child_nodes
(
	vr_application_id	UUID,
	vr_parent_node_id	UUID,
    vr_tree_id			UUID,
	vr_search_text	 	VARCHAR(500)
)
RETURNS SETOF dct_tree_node_ret_composite
AS
$$
DECLARE
	vr_ids_count	INTEGER;
	vr_ids			UUID[];
BEGIN
	IF vr_tree_id IS NULL AND vr_parent_node_id IS NULL THEN
		RETURN;
	END IF;
	
	IF COALESCE(vr_search_text, '') = '' THEN
		vr_ids := ARRAY(
			SELECT tn.tree_node_id
			FROM dct_tree_nodes AS tn
			WHERE tn.application_id = vr_application_id AND deleted = FALSE AND 
				(vr_tree_id IS NULL OR tn.tree_id = vr_tree_id) AND (
					(vr_parent_node_id IS NULL AND tn.parent_node_id IS NULL) OR 
					(vr_parent_node_id IS NOT NULL AND tn.parent_node_id = vr_parent_node_id)
				)
			ORDER BY COALESCE(tn.sequence_number, 100000) ASC, tn.name ASC, tn.creation_date ASC
		);
	ELSE
		IF vr_parent_node_id IS NOT NULL THEN
			vr_ids := ARRAY(
				SELECT vr_parent_node_id
			);
			
			vr_ids := ARRAY(
				SELECT DISTINCT h.node_id
				FROM dct_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_ids) AS h
				WHERE h.node_id <> vr_parent_node_id
			);
		END IF;
		
		vr_ids_count := COALESCE(ARRAY_LENGTH(vr_ids, 1), 0)::INTEGER;
	
		vr_ids := ARRAY(
			SELECT x.node_id
			FROM (
					SELECT	ROW_NUMBER() OVER (
								ORDER BY 	pgroonga_score(tn.tableoid, tn.ctid) DESC, 
											tn.tree_node_id ASC
							) AS "row_number",
							tn.tree_node_id AS node_id
					FROM dct_tree_nodes AS tn
						LEFT JOIN UNNEST(vr_ids) AS i
						ON i = tn.tree_node_id
					WHERE tn.application_id = vr_application_id AND 
						tn.name &@~ vr_search_text AND tn.deleted = FALSE AND 
						(vr_ids_count = 0 OR i IS NOT NULL) AND 
						(vr_tree_id IS NULL OR tn.tree_id = vr_tree_id)
				) AS x
			ORDER BY x.row_number ASC
		);
	END IF;

	RETURN QUERY
	SELECT *
	FROM dct_p_get_tree_nodes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
