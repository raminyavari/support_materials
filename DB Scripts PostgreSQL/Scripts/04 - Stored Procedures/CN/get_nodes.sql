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
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_nt_ids		UUID[];
	vr_related_ids	UUID[];
	vr_cnt			INTEGER;
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
			ON srch.key = nd.node_id
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
	
		DELETE FROM i
		FROM vr_n_ids_23043 AS i
			LEFT JOIN (
				SELECT r.node_id, r.related_node_id
				FROM cn_fn_get_related_node_ids(vr_application_id, 
					vr_related_ids, NULL, NULL, TRUE, TRUE, TRUE, TRUE) AS r
			) AS x
			ON x.related_node_id = i.node_id
		WHERE x.related_node_id IS NULL;
	END IF;
	
	IF vr_creator_user_id IS NOT NULL THEN
		DELETE FROM i
		FROM vr_n_ids_23043 AS i
			LEFT JOIN cn_node_creators AS nc
			ON nc.application_id = vr_application_id AND nc.node_id = i.node_id AND 
				nc.user_id = vr_creator_user_id AND nc.deleted = FALSE
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = i.node_id
		WHERE nc.node_id IS NULL AND nd.creator_user_id <> vr_creator_user_id;
	END IF;
	
	IF COALESCE(vr_check_access, FALSE) = TRUE THEN
		DECLARE vr__t_ids KeyLessGuidTableType
		
		INSERT INTO vr__t_ids (Value)
		SELECT NodeID
		FROM vr__n_ids AS i_ds
		
		DECLARE	vr_permission_types StringPairTableType
		
		INSERT INTO vr_permission_types (FirstValue, SecondValue)
		VALUES (N'View', vr_default_privacy), (N'ViewAbstract', vr_default_privacy)
	
		DELETE I
		FROM vr__n_ids AS i
			LEFT JOIN (
				SELECT a.id
				FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
					vr__t_ids, 'Node', NOW(), vr_permission_types) AS a
				GROUP BY a.id
			) AS x
			ON x.id = i.node_id
		WHERE x.id IS NULL;
	END IF;
	
	DECLARE vr_node_ids KeyLessGuidTableType
	DECLARE vr_total_count bigint = NULL
	
	IF (SELECT COUNT(*) FROM vr_form_filters) > 0 BEGIN
		DECLARE vr_iDs GuidTableType
		
		INSERT INTO vr_iDs (Value)
		SELECT NodeID
		FROM vr__n_ids
		
		INSERT INTO vr_node_ids (Value)
		SELECT ref.owner_id
		FROM vr__n_ids AS i_ds
			INNER JOIN fg_fn_filter_instance_owners(vr_application_id, NULL, vr_iDs, vr_form_filters, vr_match_allFilters) AS ref
			ON ref.owner_id = i_ds.node_id
		ORDER BY ref.rank ASC, i_ds.creation_date DESC, ref.owner_id DESC
		
		SET vr_total_count = (SELECT COUNT(*) FROM vr_node_ids)
	END
	ELSE BEGIN
		INSERT INTO vr_node_ids (Value)
		SELECT i_ds.node_id
		FROM vr__n_ids AS i_ds
		ORDER BY i_ds.score DESC, i_ds.creation_date DESC, i_ds.node_id DESC
		
		SET vr_total_count = (SELECT COUNT(*) FROM vr__n_ids)
	END
	
	DECLARE vr_element_type varchar(50) = NULL
	DECLARE vr_nodeTypeID UUID = NULL
	
	IF vr_group_by_form_element_id IS NOT NULL AND vr_cnt = 1 BEGIN
		SET vr_element_type = (
			SELECT TOP(1) e.type
			FROM fg_extended_form_elements AS e
			WHERE e.application_id = vr_application_id AND e.element_id = vr_group_by_form_element_id
		)
		
		IF vr_element_type = N'Select' BEGIN 
			SELECT	e.text_value, 
					CAST(NULL AS boolean) AS bit_value, 
					vr_element_type AS type, 
					COUNT(DISTINCT nd.value) AS count
			FROM vr_node_ids AS nd
				LEFT JOIN fg_form_instances AS i
				ON i.application_id = vr_application_id AND i.owner_id = nd.value
				LEFT JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.ref_element_id = vr_group_by_form_element_id
			GROUP BY e.text_value
			ORDER BY count DESC
		END 
		ELSE IF vr_element_type = N'Binary' BEGIN
			SELECT	CAST(NULL AS varchar(max)) AS text_value, 
					e.bit_value, 
					vr_element_type AS type, 
					COUNT(DISTINCT nd.value) AS count
			FROM vr_node_ids AS nd
				LEFT JOIN fg_form_instances AS i
				ON i.application_id = vr_application_id AND i.owner_id = nd.value
				LEFT JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.ref_element_id = vr_group_by_form_element_id
			GROUP BY e.bit_value
			ORDER BY count DESC
		END
	END
	ELSE BEGIN
		DECLARE vr_retIDs KeyLessGuidTableType

		-- Pick Items
		IF COALESCE(vr_count, 0) < 1 SET vr_count = 1000000000
		IF COALESCE(vr_lower_boundary, 0) < 1 SET vr_lower_boundary = 1
		
		INSERT INTO vr_retIDs (value)
		SELECT i_ds.value
		FROM vr_node_ids AS i_ds
		WHERE i_ds.sequence_number BETWEEN vr_lower_boundary AND (vr_lower_boundary + vr_count - 1)
		-- end of Pick Items
		
		EXEC cn_p_get_nodes_by_ids vr_application_id, vr_retIDs, 0, NULL
		
		SELECT vr_total_count

		IF vr_fetch_counts = 1 BEGIN
			SELECT	nd.node_type_id,
					MAX(nd.type_additional_id) AS node_type_additional_id,
					MAX(nd.type_name) AS type_name,
					COUNT(DISTINCT nd.node_id) AS nodes_count
			FROM vr_node_ids AS i_ds
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
			GROUP BY nd.node_type_id
		END
	END
END;
$$ LANGUAGE plpgsql;
