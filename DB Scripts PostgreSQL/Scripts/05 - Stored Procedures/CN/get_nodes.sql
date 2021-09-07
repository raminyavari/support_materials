DROP FUNCTION IF EXISTS cn_get_nodes;

CREATE OR REPLACE FUNCTION cn_get_nodes
(
	vr_application_id				UUID,
	vr_current_user_id				UUID,
	vr_node_type_ids		 		guid_table_type[],
	vr_node_type_additional_id 		VARCHAR(50),
	vr_use_node_type_hierarchy 		BOOLEAN,
	vr_related_to_node_id			UUID,
    vr_search_text			 		VARCHAR(1000),
    vr_is_document			 		BOOLEAN,
    vr_is_knowledge		 			BOOLEAN,
    vr_creator_user_id				UUID,
    vr_searchable			 		BOOLEAN,
    vr_archive			 			BOOLEAN,
    vr_grab_no_content_services 	BOOLEAN,
    vr_lower_creation_date_limit	TIMESTAMP,
    vr_upper_creation_date_limit 	TIMESTAMP,
    vr_count				 		INTEGER,
    vr_lower_boundary				BIGINT,
    vr_form_filters					form_filter_table_type[],
    vr_match_all_filters	 		BOOLEAN,
	vr_fetch_counts		 			BOOLEAN,
    vr_check_access		 			BOOLEAN,
    vr_default_privacy				VARCHAR(20),
    vr_group_by_form_element_id		UUID
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_nt_ids			UUID[];
	vr_related_ids		UUID[];
	vr_cnt				INTEGER;
	vr_temp_ids			UUID[];
	vr_permission_types string_pair_table_type[];
	vr_element_type 	VARCHAR(50);
	vr_node_type_id 	UUID;
	vr_node_ids			UUID[];
	vr_total_count		BIGINT;
	vr_group_ref		REFCURSOR;
	vr_nodes_ref		REFCURSOR;
	vr_total_count_ref	REFCURSOR;
	vr_node_counts_ref	REFCURSOR;
BEGIN
	vr_search_text := gfn_verify_string(vr_search_text);

	vr_nt_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_node_type_ids) AS x
	);
	
	vr_cnt := COALESCE(ARRAY_LENGTH(vr_nt_ids, 1), 0)::INTEGER;
	
	IF vr_cnt = 0 THEN
		vr_nt_ids := ARRAY(
			SELECT nt.node_type_id
			FROM cn_node_types AS nt
			WHERE application_id = vr_application_id AND additional_id = vr_node_type_additional_id
		);
		
		vr_cnt := COALESCE(ARRAY_LENGTH(vr_nt_ids, 1), 0)::INTEGER;
	END IF;
	
	IF vr_use_node_type_hierarchy = TRUE AND vr_cnt > 0 THEN
		vr_nt_ids := ARRAY(
			SELECT UNNEST(vr_nt_ids) AS x
			
			UNION ALL
			
			SELECT DISTINCT rf.node_type_id
			FROM UNNEST(vr_nt_ids) AS y
				RIGHT JOIN cn_fn_get_child_node_types_deep_hierarchy(vr_application_id, vr_nt_ids) AS rf
				ON rf.node_type_id = y
			WHERE y IS NULL
		);
	
		vr_cnt := COALESCE(ARRAY_LENGTH(vr_nt_ids, 1), 0)::INTEGER;
	END IF;
	
	DROP TABLE IF EXISTS vr_n_ids_23043;
	
	CREATE TEMP TABLE vr_n_ids_23043 (
		node_id 		UUID, 
		score 			FLOAT, 
		total_count 	BIGINT, 
		creation_date 	TIMESTAMP
	);
	
	IF COALESCE(vr_search_text, N'') = N'' THEN
		INSERT INTO vr_n_ids_23043 (node_id, creation_date)
		SELECT nd.node_id, nd.creation_date
		FROM cn_view_nodes_normal AS nd
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
		WHERE nd.application_id = vr_application_id AND 
			(vr_cnt = 0 OR nd.node_type_id IN (SELECT UNNEST(vr_nt_ids))) AND
			(vr_is_document IS NULL OR COALESCE(s.is_document, FALSE) = vr_is_document) AND
			(vr_is_knowledge IS NULL OR COALESCE(s.is_knowledge, FALSE) = vr_is_knowledge) AND
			(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
			(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit) AND
			(vr_archive IS NULL OR nd.deleted = vr_archive) AND
			(vr_searchable IS NULL OR COALESCE(nd.searchable, TRUE) = vr_searchable) AND
			(
				(vr_cnt = 1 AND (COALESCE(vr_grab_no_content_services, FALSE) = TRUE OR 
					COALESCE(s.no_content, FALSE) = FALSE OR nd.creator_user_id = vr_current_user_id)) OR
				(vr_cnt <> 1 AND COALESCE(s.no_content, FALSE) = FALSE)
			);
	ELSE
		INSERT INTO vr_n_ids_23043 (node_id, score, creation_date)
		SELECT nd.node_id, pgroonga_score(nd.tableoid, nd.ctid)::FLOAT, nd.creation_date
		FROM cn_view_nodes_normal AS nd
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
		WHERE nd.application_id = vr_application_id AND (
				nd.name &@~ vr_search_text OR nd.additional_id &@~ vr_search_text OR
				nd.tags &@~ vr_search_text
			) AND
			(vr_cnt = 0 OR nd.node_type_id IN (SELECT UNNEST(vr_nt_ids))) AND
			(vr_is_document IS NULL OR COALESCE(s.is_document, FALSE) = vr_is_document) AND
			(vr_is_knowledge IS NULL OR COALESCE(s.is_knowledge, FALSE) = vr_is_knowledge) AND
			(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
			(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit) AND
			(vr_archive IS NULL OR nd.deleted = vr_archive) AND
			(vr_searchable IS NULL OR COALESCE(nd.searchable, TRUE) = vr_searchable) AND
			(
				(vr_cnt = 1 AND (COALESCE(vr_grab_no_content_services, FALSE) = TRUE OR 
					COALESCE(s.no_content, FALSE) = FALSE OR nd.creator_user_id = vr_current_user_id)) OR
				(vr_cnt <> 1 AND COALESCE(s.no_content, FALSE) = FALSE)
			);
	END IF;
	
	IF vr_related_to_node_id IS NOT NULL THEN
		vr_related_ids := ARRAY(
			SELECT vr_related_to_node_id
		);
		
		WITH rf AS
		(
			SELECT i.node_id
			FROM vr_n_ids_23043 AS i
				LEFT JOIN (
					SELECT r.node_id, r.related_node_id
					FROM cn_fn_get_related_node_ids(vr_application_id, 
						vr_related_ids, NULL, NULL, TRUE, TRUE, TRUE, TRUE) AS r
				) AS x
				ON x.related_node_id = i.node_id
			WHERE x.related_node_id IS NULL
		)
		DELETE FROM vr_n_ids_23043 AS i
		USING rf
		WHERE i.node_id = rf.node_id;
	END IF;
	
	IF vr_creator_user_id IS NOT NULL THEN
		WITH rf AS
		(
			SELECT i.node_id
			FROM vr_n_ids_23043 AS i
				LEFT JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.node_id = i.node_id AND 
					nc.user_id = vr_creator_user_id AND nc.deleted = FALSE
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = i.node_id
			WHERE nc.node_id IS NULL AND nd.creator_user_id <> vr_creator_user_id
		)
		DELETE FROM vr_n_ids_23043 AS i
		USING rf
		WHERE i.node_id = rf.node_id;
	END IF;
	
	IF COALESCE(vr_check_access, FALSE) = TRUE THEN
		vr_temp_ids := ARRAY(
			SELECT x.node_id
			FROM vr_n_ids_23043 AS x
		);
		
		vr_permission_types := ARRAY(
			SELECT ROW('View', vr_default_privacy)
			UNION ALL
			SELECT ROW('ViewAbstract', vr_default_privacy)
		);
		
		WITH rf AS
		(
			SELECT i.node_id
			FROM vr_n_ids_23043 AS i
				LEFT JOIN (
					SELECT "a".id
					FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
						vr_temp_ids, 'Node', NOW(), vr_permission_types) AS "a"
					GROUP BY "a".id
				) AS x
				ON x.id = i.node_id
			WHERE x.id IS NULL
		)
		DELETE FROM vr_n_ids_23043 AS i
		USING rf
		WHERE i.node_id = rf.node_id;
	END IF;
	
	IF COALESCE(ARRAY_LENGTH(vr_form_filters, 1), 0) > 0 THEN
		vr_temp_ids := ARRAY(
			SELECT x.node_id
			FROM vr_n_ids_23043 AS x
		);
		
		vr_node_ids := ARRAY(
			SELECT rf.owner_id
			FROM vr_n_ids_23043 AS ids
				INNER JOIN fg_fn_filter_instance_owners(vr_application_id, 
														NULL, vr_temp_ids, vr_form_filters, vr_match_all_filters) AS rf
				ON rf.owner_id = ids.node_id
			ORDER BY rf.rank ASC, ids.creation_date DESC, rf.owner_id DESC
		);
	ELSE
		vr_node_ids := ARRAY(
			SELECT ids.node_id
			FROM vr_n_ids_23043 AS ids
			ORDER BY ids.score DESC, ids.creation_date DESC, ids.node_id DESC
		);
	END IF;
	
	vr_total_count := COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0)::BIGINT;
	
	IF vr_group_by_form_element_id IS NOT NULL AND vr_cnt = 1 THEN
		SELECT vr_element_type = e.type
		FROM fg_extended_form_elements AS e
		WHERE e.application_id = vr_application_id AND e.element_id = vr_group_by_form_element_id
		LIMIT 1;
		
		IF vr_element_type = 'Select' THEN
			OPEN vr_group_ref FOR
			SELECT	e.text_value, 
					NULL::BOOLEAN AS bit_value, 
					vr_element_type AS "type", 
					COUNT(DISTINCT nd) AS "count"
			FROM UNNEST(vr_node_ids) AS nd
				LEFT JOIN fg_form_instances AS i
				ON i.application_id = vr_application_id AND i.owner_id = nd
				LEFT JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND 
					e.ref_element_id = vr_group_by_form_element_id
			GROUP BY e.text_value
			ORDER BY "count" DESC;
			
			RETURN NEXT vr_group_ref;
		ELSEIF vr_element_type = 'Binary' THEN
			OPEN vr_group_ref FOR
			SELECT	NULL::VARCHAR AS text_value, 
					e.bit_value, 
					vr_element_type AS "type", 
					COUNT(DISTINCT nd) AS "count"
			FROM UNNEST(vr_node_ids) AS nd
				LEFT JOIN fg_form_instances AS i
				ON i.application_id = vr_application_id AND i.owner_id = nd
				LEFT JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND 
					e.ref_element_id = vr_group_by_form_element_id
			GROUP BY e.bit_value
			ORDER BY "count" DESC;
			
			RETURN NEXT vr_group_ref;
		END IF;
	ELSE
		-- Pick Items
		IF COALESCE(vr_count, 0) < 1 THEN 
			vr_count := 1000000000;
		END IF;
		
		IF COALESCE(vr_lower_boundary, 0) < 1 THEN
			vr_lower_boundary := 1;
		END IF;
		
		vr_temp_ids := ARRAY(
			SELECT x.id
			FROM UNNEST(vr_node_ids) WITH ORDINALITY AS x("id", seq)
			WHERE x.seq BETWEEN vr_lower_boundary AND (vr_lower_boundary + vr_count - 1)
		);
		-- end of Pick Items
		
		OPEN vr_nodes_ref FOR
		SELECT *
		FROM cn_p_get_nodes_by_ids(vr_application_id, vr_temp_ids, FALSE, NULL);
		
		RETURN NEXT vr_nodes_ref;
		
		OPEN vr_total_count_ref FOR
		SELECT vr_total_count;
		
		RETURN NEXT vr_total_count_ref;

		IF vr_fetch_counts = TRUE THEN
			OPEN vr_node_counts_ref FOR
			SELECT	nd.node_type_id,
					MAX(nd.type_additional_id) AS node_type_additional_id,
					MAX(nd.type_name) AS type_name,
					COUNT(DISTINCT nd.node_id) AS nodes_count
			FROM UNNEST(vr_node_ids) AS x
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = x
			GROUP BY nd.node_type_id;
			
			RETURN NEXT vr_node_counts_ref;
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;
