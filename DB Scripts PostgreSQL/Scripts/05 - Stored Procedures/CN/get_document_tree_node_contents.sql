DROP FUNCTION IF EXISTS cn_get_document_tree_node_contents;

CREATE OR REPLACE FUNCTION cn_get_document_tree_node_contents
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_current_user_id	UUID,
	vr_check_privacy 	BOOLEAN,
	vr_now		 		TIMESTAMP,
	vr_default_privacy 	VARCHAR(20),
	vr_count		 	INTEGER,
	vr_lower_boundary	INTEGER,
	vr_search_text	 	VARCHAR(500)
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_tree_id 			UUID;
	vr_tree_node_ids	UUID[];
	vr_permission_types string_pair_table_type[];
	vr_ret_ids			UUID[];
	vr_total_count		BIGINT;
BEGIN
	SELECT vr_tree_id = tr.tree_id
	FROM dct_trees AS tr
	WHERE tr.application_id = vr_application_id AND tr.tree_id = vr_tree_node_id
	LIMIT 1;
	
	IF vr_tree_id IS NOT NULL THEN
		vr_tree_node_id := NULL;
	END IF;
		
	IF COALESCE(vr_search_text, '') = '' THEN
		vr_ret_ids := ARRAY(
			SELECT x.node_id
			FROM (
					SELECT nd.node_id, MAX(COALESCE(tc.creation_date, nd.creation_date)) AS creation_date
					FROM dct_tree_nodes AS tn
						LEFT JOIN dct_tree_node_contents AS tc
						ON tc.application_id = vr_application_id AND 
							tc.tree_node_id = tn.tree_node_id AND tc.deleted = FALSE
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.deleted = FALSE AND (
								(tc.node_id IS NOT NULL AND nd.node_id = tc.node_id) OR 
								(nd.document_tree_node_id IS NOT NULL AND nd.document_tree_node_id = tn.tree_node_id)
							)
					WHERE tn.application_id = vr_application_id AND (
							(vr_tree_id IS NOT NULL AND tn.tree_id = vr_tree_id AND tn.deleted = FALSE) OR
							(vr_tree_node_id IS NOT NULL AND tn.tree_node_id = vr_tree_node_id)
						)
					GROUP BY nd.node_id
				) AS x
			ORDER BY x.creation_date DESC
		);
	ELSE
		IF vr_tree_id IS NULL AND vr_tree_node_id IS NOT NULL THEN
			vr_tree_node_ids := ARRAY(
				SELECT vr_tree_node_id
			);
		
			vr_tree_node_ids := ARRAY(
				SELECT vr_tree_node_id
				
				UNION ALL
				
				SELECT DISTINCT rf.node_id
				FROM dct_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_tree_node_ids) AS rf
				WHERE rf.node_id <> vr_tree_node_id
			);
		END IF;
	
		vr_ret_ids := ARRAY(
			SELECT x.node_id
			FROM (
					SELECT "a".node_id, MAX("a".row_number) AS row_number
					FROM (
							SELECT	ROW_NUMBER() OVER (
										ORDER BY 	pgroonga_score(nd.tableoid, nd.ctid) DESC, 
													nd.node_id ASC
									) AS "row_number",
									nd.node_id
							FROM dct_tree_nodes AS tn
								LEFT JOIN dct_tree_node_contents AS tc
								ON tc.application_id = vr_application_id AND 
									tc.tree_node_id = tn.tree_node_id AND tc.deleted = FALSE
								INNER JOIN cn_nodes AS nd
								ON nd.application_id = vr_application_id AND 
									nd.name &@~ vr_search_text AND nd.deleted = FALSE AND (
										(tc.node_id IS NOT NULL AND nd.node_id = tc.node_id) OR 
										(nd.document_tree_node_id IS NOT NULL AND nd.document_tree_node_id = tn.tree_node_id)
									)
							WHERE tn.application_id = vr_application_id AND (
									(vr_tree_id IS NOT NULL AND tn.tree_id = vr_tree_id AND tn.deleted = FALSE) OR
									(vr_tree_node_id IS NOT NULL AND tn.tree_node_id IN (SELECT UNNEST(vr_tree_node_ids)))
								)
						) AS "a"
					GROUP BY "a".node_id
				) AS x
			ORDER BY x.row_number ASC
		);
	END IF;
	
	IF vr_check_privacy = TRUE THEN
		vr_permission_types := ARRAY(
			SELECT ROW('View', vr_default_privacy)
		);
		
		vr_ret_ids := ARRAY(
			SELECT rf.id
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_ret_ids, 'Node', vr_now, vr_permission_types) AS rf
		);
	END IF;
	
	vr_total_count := COALESCE(ARRAY_LENGTH(vr_ret_ids, 1), 0)::BIGINT;
	
	vr_ret_ids := ARRAY(
		SELECT x.id
		FROM (
				SELECT	ROW_NUMBER() OVER(ORDER BY v.seq ASC) AS "row_number",
						v.id
				FROM UNNEST(vr_ret_ids) WITH ORDINALITY AS v("id", seq)
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
		LIMIT COALESCE(vr_count, 1000)
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, NULL, NULL, vr_total_count);
END;
$$ LANGUAGE plpgsql;
