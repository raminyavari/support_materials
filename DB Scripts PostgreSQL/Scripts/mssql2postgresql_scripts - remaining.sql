
DROP PROCEDURE IF EXISTS cn_get_document_tree_node_contents;

CREATE PROCEDURE cn_get_document_tree_node_contents
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_current_user_id	UUID,
	vr_check_privacy BOOLEAN,
	vr_now		 TIMESTAMP,
	vr_default_privacy varchar(20),
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER,
	vr_searchText	 VARCHAR(500)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_temp_ids KeyLessGuidTableType
	
	DECLARE vr_tree_id UUID = (
		SELECT TOP(1) TreeID
		FROM dct_trees
		WHERE ApplicationID = vr_application_id AND TreeID = vr_tree_node_id
	)
	
	IF vr_tree_id IS NOT NULL SET vr_tree_node_id = NULL
	
	IF COALESCE(vr_searchText, N'') = N'' BEGIN
		INSERT INTO vr_temp_ids (Value)
		SELECT x.node_id
		FROM (
				SELECT nd.node_id, MAX(COALESCE(c.creation_date, nd.creation_date)) AS creation_date
				FROM dct_tree_nodes AS t
					LEFT JOIN dct_tree_node_contents AS c
					ON c.application_id = vr_application_id AND c.tree_node_id = t.tree_node_id AND c.deleted = FALSE
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.deleted = FALSE AND 
						(
							(c.node_id IS NOT NULL AND nd.node_id = c.node_id) OR 
							(nd.document_tree_node_id IS NOT NULL AND nd.document_tree_node_id = t.tree_node_id)
						)
				WHERE t.application_id = vr_application_id AND
					(
						(vr_tree_id IS NOT NULL AND t.tree_id = vr_tree_id AND t.deleted = FALSE) OR
						(vr_tree_node_id IS NOT NULL AND t.tree_node_id = vr_tree_node_id)
					)
				GROUP BY nd.node_id
			) AS x
		ORDER BY x.creation_date DESC
	END
	ELSE BEGIN
		DECLARE vr_t_n_ids GuidTableType
		
		IF vr_tree_id IS NULL AND vr_tree_node_id IS NOT NULL BEGIN
			INSERT INTO vr_t_n_ids (Value)
			VALUES (vr_tree_node_id)
		
			INSERT INTO vr_t_n_ids (Value)
			SELECT DISTINCT ref.node_id
			FROM d_c_t_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_t_n_ids) AS ref
			WHERE ref.node_id <> vr_tree_node_id
		END
	
	
		INSERT INTO vr_temp_ids (Value)
		SELECT x.node_id
		FROM (
				SELECT a.node_id, MAX(a.row_number) AS row_number
				FROM (
						SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key ASC) AS row_number,
								srch.key AS node_id
						FROM CONTAINSTABLE(cn_nodes, (Name), vr_searchText) AS srch
							INNER JOIN dct_tree_nodes AS t
							LEFT JOIN dct_tree_node_contents AS c
							ON c.application_id = vr_application_id AND c.tree_node_id = t.tree_node_id AND c.deleted = FALSE
							INNER JOIN cn_nodes AS nd
							ON nd.application_id = vr_application_id AND nd.deleted = FALSE AND 
								(
									(c.node_id IS NOT NULL AND nd.node_id = c.node_id) OR 
									(nd.document_tree_node_id IS NOT NULL AND nd.document_tree_node_id = t.tree_node_id)
								)
							ON nd.node_id = srch.key
						WHERE t.application_id = vr_application_id AND
							(
								(vr_tree_id IS NOT NULL AND t.tree_id = vr_tree_id AND t.deleted = FALSE) OR
								(vr_tree_node_id IS NOT NULL AND t.tree_node_id IN (SELECT b.value FROM vr_t_n_ids AS b))
							)
					) AS a
				GROUP BY a.node_id
			) AS x
		ORDER BY x.row_number ASC
	END
	
	DECLARE vr_iDs KeyLessGuidTableType
	
	IF vr_check_privacy = 1 BEGIN
		DECLARE	vr_permission_types StringPairTableType
		
		INSERT INTO vr_permission_types (FirstValue, SecondValue)
		VALUES (N'View', vr_default_privacy)
	
		INSERT INTO vr_iDs (Value)
		SELECT ref.id
		FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
			vr_temp_ids, N'Node', vr_now, vr_permission_types) AS ref
	END
	ELSE BEGIN
		INSERT INTO vr_iDs (Value)
		SELECT ref.value AS id
		FROM vr_temp_ids AS ref
	END
	
	DELETE vr_temp_ids
	
	INSERT INTO vr_temp_ids (Value)
	SELECT TOP(COALESCE(vr_count, 1000)) x.value
	FROM (
			SELECT	ROW_NUMBER() OVER(ORDER BY id.sequence_number ASC) AS row_number,
					id.value
			FROM vr_iDs AS id
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
	
	EXEC cn_p_get_nodes_by_ids vr_application_id, vr_temp_ids, NULL, NULL
	
	SELECT CAST(COUNT(id.value) AS bigint) AS total_count
	FROM vr_iDs AS id
END;


DROP PROCEDURE IF EXISTS cn_is_node_type;

CREATE PROCEDURE cn_is_node_type
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ref.value AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ref.value
END;


DROP PROCEDURE IF EXISTS cn_is_node;

CREATE PROCEDURE cn_is_node
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ref.value AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
		INNER JOIN cn_nodes AS nt
		ON nt.application_id = vr_application_id AND nt.node_id = ref.value
END;


DROP PROCEDURE IF EXISTS cn_explore;

CREATE PROCEDURE cn_explore
	vr_application_id		UUID,
	vr_baseID				UUID,
	vr_related_id			UUID,
	vr_strBaseTypeIDs		varchar(max),
	vr_strRelatedTypeIDs	varchar(max),
	vr_delimiter			char,
	vr_secondLevelNodeID	UUID,
	vr_registration_area BOOLEAN,
	vr_tags			 BOOLEAN,
	vr_relations		 BOOLEAN,
	vr_lower_boundary	 INTEGER,
	vr_count			 INTEGER,
	vr_orderBy			varchar(100),
	vr_orderByDesc	 BOOLEAN,
	vr_searchText		 VARCHAR(1000),
	vr_check_access	 BOOLEAN,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP,
	vr_default_privacy		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_baseTypeIDs GuidTableType, vr_related_type_ids GuidTableType
	
	INSERT INTO vr_baseTypeIDs
	SELECT *
	FROM gfn_str_to_guid_table(vr_strBaseTypeIDs, vr_delimiter)
	
	INSERT INTO vr_related_type_ids
	SELECT *
	FROM gfn_str_to_guid_table(vr_strRelatedTypeIDs, vr_delimiter)
	
	IF vr_orderBy = 'Type' SET vr_orderBy = 'RelatedType'	
	ELSE IF vr_orderBy = N'Date' SET vr_orderBy = 'RelatedCreationDate'	
	ELSE SET vr_orderBy = 'RelatedName'
	
	DECLARE vr_sortOrder varchar(10) = 'ASC', vr_rev_sort_order varchar(10) = 'DESC'
	IF vr_orderByDesc = 1 BEGIN 
		SET vr_sortOrder = 'DESC'
		SET vr_rev_sort_order = 'ASC'
	END
	
	DECLARE vr_baseIDs GuidTableType
	
	IF vr_baseID IS NOT NULL BEGIN
		INSERT INTO vr_baseIDs (Value)
		VALUES (vr_baseID)
		
		IF COALESCE(vr_searchText, N'') <> N'' BEGIN
			INSERT INTO vr_baseIDs (Value)
			SELECT DISTINCT h.node_id
			FROM vr_baseIDs AS b
				RIGHT JOIN cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_baseIDs) AS h
				ON h.node_id = b.value
			WHERE b.value IS NULL AND h.node_id <> vr_baseID
		END
	END
	
	CREATE TABLE #Items (BaseID UUID,
		BaseTypeID UUID, BaseName VARCHAR(2000), BaseType VARCHAR(2000), 
		RelatedID UUID, RelatedTypeID UUID, RelatedName VARCHAR(2000),
		RelatedType VARCHAR(2000), RelatedCreationDate TIMESTAMP,
		IsTag BOOLEAN, IsRelation BOOLEAN, IsRegistrationArea BOOLEAN,
		PRIMARY KEY (BaseID, RelatedID)
	)

	INSERT INTO #Items
	SELECT	ref.base_id,
			CAST(MAX(CAST(ref.base_type_id AS varchar(100))) AS uuid),
			MAX(ref.base_name),
			MAX(ref.base_type),
			ref.related_id,
			CAST(MAX(CAST(ref.related_type_id AS varchar(100))) AS uuid),
			MAX(ref.related_name),
			MAX(ref.related_type),
			MAX(ref.related_creation_date),
			CAST(MAX(CAST(ref.is_tag AS integer)) AS boolean),
			CAST(MAX(CAST(ref.is_relation AS integer)) AS boolean),
			CAST(MAX(CAST(ref.is_registration_area AS integer)) AS boolean)
	FROM cn_fn_explore(vr_application_id, vr_baseIDs, vr_baseTypeIDs, 
		vr_related_id, vr_related_type_ids, vr_registration_area, vr_tags, vr_relations) AS ref
	GROUP By ref.base_id, ref.related_id
	
	IF vr_secondLevelNodeID IS NOT NULL BEGIN
		DECLARE vr_bIDs GuidTableType
		DECLARE vr_bTIDs GuidTableType
		
		INSERT INTO vr_bIDs (Value) VALUES (vr_secondLevelNodeID)
	
		DELETE I
		FROM #Items AS i
			LEFT JOIN (
				SELECT r.node_id, r.related_node_id
				FROM cn_fn_get_related_node_ids(vr_application_id, 
					vr_bIDs, vr_bTIDs, vr_related_type_ids, vr_relations, vr_relations, vr_tags, vr_tags) AS r
			) AS x
			ON x.related_node_id = i.related_id
		WHERE x.related_node_id IS NULL
	END
	
	
	IF COALESCE(vr_check_access, 0) = 1 BEGIN
		DECLARE vr_temp_ids KeyLessGuidTableType
		
		INSERT INTO vr_temp_ids (Value)
		SELECT RelatedID
		FROM #Items
		
		DECLARE	vr_permission_types StringPairTableType
		
		INSERT INTO vr_permission_types (FirstValue, SecondValue)
		VALUES (N'View', vr_default_privacy)
	
		DELETE I
		FROM #Items AS i
			LEFT JOIN prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_temp_ids, N'Node', vr_now, vr_permission_types) AS a
			ON a.id = i.related_id
		WHERE a.id IS NULL
	END
	
	IF COALESCE(vr_searchText, N'') = N'' BEGIN	
		DECLARE vr_to_be_executed varchar(2000) = 
			'SELECT TOP(' + CAST(COALESCE(vr_count, 100) AS varchar(100)) + ') ' +
				'CAST((x.row_number + x.rev_row_number - 1) AS bigint) AS total_count, ' +
				'x.base_id, x.base_type_id, x.base_name, x.base_type, ' +
				'x.related_id, x.related_type_id, x.related_name, x.related_type, ' +
				'x.related_creation_date, x.is_tag, x.is_relation, x.is_registration_area ' +
			'FROM ( ' +
					'SELECT	ROW_NUMBER() OVER (ORDER BY i.' + vr_orderBy + ' ' + 
								vr_sortOrder + ', i.related_id ASC) AS row_number, ' +
							'ROW_NUMBER() OVER (ORDER BY i.' + vr_orderBy + ' ' + 
								vr_rev_sort_order + ', i.related_id DESC) AS rev_row_number, ' +
							'i.* ' +
					'FROM #Items AS i ' +
				') AS x ' +
			'WHERE x.row_number >= ' + CAST(COALESCE(vr_lower_boundary, 0) AS varchar(100)) + ' ' +
			'ORDER BY x.row_number ASC '
			
		EXEC (vr_to_be_executed)
	END
	ELSE BEGIN
		SELECT TOP(COALESCE(vr_count, 100))
			CAST((x.row_number + x.rev_row_number - 1) AS bigint) AS total_count,
			x.base_id, x.base_type_id, x.base_name, x.base_type,
			x.related_id, x.related_type_id, x.related_name, x.related_type,
			x.related_creation_date, x.is_tag, x.is_relation, x.is_registration_area
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, srch.key DESC) AS rev_row_number,
						ref.*
				FROM CONTAINSTABLE(cn_nodes, (name, additional_id), vr_searchText) AS srch
					INNER JOIN (
						SELECT	CAST(MAX(CAST(i.base_id AS varchar(100))) AS uuid) AS base_id,
								CAST(MAX(CAST(i.base_type_id AS varchar(100))) AS uuid) AS base_type_id,
								MAX(i.base_name) AS base_name,
								MAX(i.base_type) AS base_type,
								i.related_id,
								CAST(MAX(CAST(i.related_type_id AS varchar(100))) AS uuid) AS related_type_id,
								MAX(i.related_name) AS related_name,
								MAX(i.related_type) AS related_type,
								MAX(i.related_creation_date) AS related_creation_date,
								CAST(MAX(CAST(i.is_tag AS integer)) AS boolean) AS is_tag,
								CAST(MAX(CAST(i.is_relation AS integer)) AS boolean) AS is_relation,
								CAST(MAX(CAST(i.is_registration_area AS integer)) AS boolean) AS is_registration_area
						FROM #Items AS i
						GROUP BY i.related_id
					) AS ref
					ON ref.related_id = srch.key
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
END;


DROP PROCEDURE IF EXISTS cn_p_update_form_and_wiki_tags;

CREATE PROCEDURE cn_p_update_form_and_wiki_tags
	vr_application_id	UUID,
	vr_node_idsTemp	GuidTableType readonly,
	vr_creator_user_id	UUID,
	vr_form		 BOOLEAN,
	vr_wiki		 BOOLEAN,
	vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids SELECT * FROM vr_node_idsTemp
	
	DELETE T
	FROM vr_node_ids AS i_ds 
		INNER JOIN rv_tagged_items AS t
		ON t.application_id = vr_application_id AND t.context_id = i_ds.value AND
			(
				(vr_form = 1 AND t.tagged_type IN (N'Node_Form', N'User_Form')) OR 
				(vr_wiki = 1 AND t.tagged_type IN (N'Node_Wiki', N'User_Wiki'))
			)

	;WITH hierarchy (ElementID, NodeID, level, type)
 AS 
	(
		SELECT e.element_id, n.value AS node_id, 0 AS level, e.type
		FROM vr_node_ids AS n
			INNER JOIN fg_form_instances AS i
			ON i.application_id = vr_application_id AND i.owner_id = n.value AND i.deleted = FALSE
			INNER JOIN fg_instance_elements AS e
			ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.deleted = FALSE
		WHERE vr_form = 1
		
		UNION ALL
		
		SELECT e.element_id, hr.node_id, level + 1, e.type
		FROM hierarchy AS hr
			INNER JOIN fg_form_instances AS i
			ON i.application_id = vr_application_id AND i.owner_id = hr.element_id AND i.deleted = FALSE
			INNER JOIN fg_instance_elements AS e
			ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.deleted = FALSE
		WHERE vr_form = 1 AND e.element_id <> hr.element_id
	)


	INSERT INTO rv_tagged_items (
		ApplicationID, 
		ContextID, 
		ContextType, 
		TaggedID, 
		TaggedType, 
		UniqueID, 
		CreatorUserID
	)
	SELECT vr_application_id, x.node_id, N'Node', x.tagged_id, x.tagged_type, gen_random_uuid(), vr_creator_user_id
	FROM (
			SELECT a.node_id, a.tagged_id, MAX(a.tagged_type) AS tagged_type
			FROM (
					SELECT h.node_id, t.tagged_id, t.tagged_type + N'_Form' AS tagged_type
					FROM hierarchy AS h
						INNER JOIN rv_tagged_items AS t
						ON t.application_id = vr_application_id AND t.context_id = h.element_id AND 
							t.tagged_type IN (N'Node', N'User')
					
					UNION

					SELECT h.node_id, s.selected_id AS tagged_id, h.type + N'_Form' AS tagged_type
					FROM hierarchy AS h
						INNER JOIN fg_selected_items AS s
						ON s.application_id = vr_application_id AND s.element_id = h.element_id AND s.deleted = FALSE
					WHERE h.type IN (N'Node', N'User')
					
					UNION
					
					SELECT t.context_id AS node_id, t.tagged_id, t.tagged_type + N'_Wiki' AS tagged_type
					FROM vr_node_ids AS i_ds
						INNER JOIN cn_view_tag_relations_wiki_context AS t
						ON t.application_id = vr_application_id AND t.context_id = i_ds.value
					WHERE vr_wiki = 1
				) AS a
			GROUP BY a.node_id, a.tagged_id
		) AS x
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.tagged_id AND nd.deleted = FALSE
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.tagged_id AND un.is_approved = TRUE
		LEFT JOIN rv_tagged_items AS t
		ON t.application_id = vr_application_id AND t.context_id = x.node_id AND
			t.tagged_id = x.tagged_id AND t.creator_user_id = vr_creator_user_id
	WHERE t.context_id IS NULL AND (nd.node_id IS NOT NULL OR un.user_id IS NOT NULL)
		
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS cn_update_form_and_wiki_tags;

CREATE PROCEDURE cn_update_form_and_wiki_tags
	vr_application_id	UUID,
	vr_strNodeIDs		varchar(max),
	vr_delimiter		char,
	vr_creator_user_id	UUID,
	vr_count		 INTEGER,
	vr_form		 BOOLEAN,
	vr_wiki		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	IF (SELECT COUNT(*) FROM vr_node_ids) = 0 BEGIN
		INSERT INTO vr_node_ids (Value)
		SELECT TOP(COALESCE(vr_count, 200)) nd.node_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE
		ORDER BY nd.index_last_update_date ASC
	END
	
	IF vr_creator_user_id IS NULL SET vr_creator_user_id = (
		SELECT TOP(1) UserID
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND LOWER(UserName) = N'admin'
	)
	
	DECLARE vr__result INTEGER
	
	EXEC cn_p_update_form_and_wiki_tags vr_application_id, vr_node_ids, vr_creator_user_id, 
		vr_form, vr_wiki, vr__result output
	
	SELECT vr__result
END;



DROP PROCEDURE IF EXISTS dct_create_tree;

CREATE PROCEDURE dct_create_tree
	vr_application_id		UUID,
    vr_tree_id 			UUID,
    vr_isPrivate		 BOOLEAN,
    vr_owner_id			UUID,
    vr_name			 VARCHAR(256),
    vr_description	 VARCHAR(1000),
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP,
    vr_privacy			varchar(20),
    vr_isTemplate		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	SET vr_description = gfn_verify_string(vr_description)
	
	INSERT INTO dct_trees(
		ApplicationID,
		TreeID,
		IsPrivate,
		OwnerID,
		Name,
		description,
		CreatorUserID,
		CreationDate,
		Privacy,
		IsTemplate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_tree_id,
		vr_isPrivate,
		vr_owner_id,
		vr_name,
		vr_description,
		vr_creator_user_id,
		vr_creation_date,
		vr_privacy,
		vr_isTemplate,
		0
	)
	
    SELECT @vr_rowcount
END;



DROP PROCEDURE IF EXISTS dct_change_tree;

CREATE PROCEDURE dct_change_tree
	vr_application_id			UUID,
    vr_tree_id					UUID,
    vr_new_name			 VARCHAR(256),
    vr_new_description		 VARCHAR(1000),
    vr_last_modifier_user_id		UUID,
    vr_last_modification_date TIMESTAMP,
    vr_isTemplate			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_new_name = gfn_verify_string(vr_new_name)
	SET vr_new_description = gfn_verify_string(vr_new_description)
	
	UPDATE dct_trees
		SET Name = vr_new_name,
			description = vr_new_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
			IsTemplate = vr_isTemplate
	WHERE ApplicationID = vr_application_id AND TreeID = vr_tree_id
	
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_p_remove_trees;

CREATE PROCEDURE dct_p_remove_trees
	vr_application_id	UUID,
    vr_tree_idsTemp	GuidTableType readonly,
    vr_owner_id		UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_ids GuidTableType
	INSERT INTO vr_tree_ids SELECT * FROM vr_tree_idsTemp
	
	UPDATE T
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_tree_ids AS i_ds
		INNER JOIN dct_trees AS t
		ON t.application_id = vr_application_id AND t.tree_id = i_ds.value AND
			((vr_owner_id IS NULL AND t.owner_id IS NULL) OR t.owner_id = vr_owner_id)
	
    SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_arithmetic_delete_tree;

CREATE PROCEDURE dct_arithmetic_delete_tree
	vr_application_id	UUID,
    vr_strTreeIDs		varchar(max),
    vr_delimiter		char,
    vr_owner_id		UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_tree_ids GuidTableType
	
	INSERT INTO vr_tree_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strTreeIDs, vr_delimiter) AS ref
	
	DECLARE vr__result INTEGER = 0
	
	EXEC dct_p_remove_trees vr_application_id, vr_tree_ids, 
		vr_owner_id, vr_current_user_id, vr_now, vr__result output
		
	IF (vr__result <> (SELECT COUNT(*) FROM vr_tree_ids)) BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT vr__result
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS dct_recycle_tree;

CREATE PROCEDURE dct_recycle_tree
	vr_application_id	UUID,
    vr_tree_id			UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE dct_trees
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND TreeID = vr_tree_id
	
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_p_get_trees_by_ids;

CREATE PROCEDURE dct_p_get_trees_by_ids
	vr_application_id	UUID,
    vr_tree_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_ids GuidTableType
	INSERT INTO vr_tree_ids SELECT * FROM vr_tree_idsTemp
	
	SELECT t.tree_id AS tree_id,
		   t.name AS name,
		   t.description AS description,
		   t.is_template AS is_template
	FROM vr_tree_ids AS external_ids 
		INNER JOIN dct_trees AS t
		ON t.application_id = vr_application_id AND external_ids.value = t.tree_id
	ORDER BY (CASE WHEN t.deleted = TRUE THEN t.sequence_number ELSE t.creation_date END) ASC
END;


DROP PROCEDURE IF EXISTS dct_get_trees_by_ids;

CREATE PROCEDURE dct_get_trees_by_ids
	vr_application_id	UUID,
    vr_strTreeIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_ids GuidTableType
	INSERT INTO vr_tree_ids 
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strTreeIDs, vr_delimiter) AS ref
	
	UPDATE IDs
		SET Value = n.tree_id
	FROM vr_tree_ids AS i_ds
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND n.tree_node_id = i_ds.value
	
	EXEC dct_p_get_trees_by_ids vr_application_id, vr_tree_ids
END;



DROP PROCEDURE IF EXISTS dct_get_trees;

CREATE PROCEDURE dct_get_trees
	vr_application_id	UUID,
    vr_owner_id		UUID,
    vr_archive	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_ids GuidTableType
	
	INSERT INTO vr_tree_ids
	SELECT ref.tree_id
	FROM dct_trees AS ref
	WHERE ref.application_id = vr_application_id AND 
		((vr_owner_id IS NULL AND ref.is_private = 0) OR ref.owner_id = vr_owner_id) AND
		ref.deleted = COALESCE(vr_archive, 0)
	
	EXEC dct_p_get_trees_by_ids vr_application_id, vr_tree_ids
END;


DROP PROCEDURE IF EXISTS dct_add_tree_node;

CREATE PROCEDURE dct_add_tree_node
	vr_application_id	UUID,
    vr_tree_node_id		UUID,
    vr_tree_id			UUID,
    vr_parent_node_id	UUID,
    vr_name		 VARCHAR(256),
    vr_description VARCHAR(1000),
    vr_creator_user_id	UUID,
    vr_creation_date TIMESTAMP,
    vr_privacy		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	SET vr_description = gfn_verify_string(vr_description)
	
	INSERT INTO dct_tree_nodes(
		ApplicationID,
		TreeNodeID,
		TreeID,
		ParentNodeID,
		Name,
		description,
		CreatorUserID,
		CreationDate,
		Privacy,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_tree_node_id,
		vr_tree_id,
		vr_parent_node_id,
		vr_name,
		vr_description,
		vr_creator_user_id,
		vr_creation_date,
		vr_privacy,
		0
	)
	
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_change_tree_node;

CREATE PROCEDURE dct_change_tree_node
	vr_application_id			UUID,
    vr_tree_node_id				UUID,
    vr_new_name			 VARCHAR(256),
    vr_new_description		 VARCHAR(1000),
    vr_last_modifier_user_id		UUID,
    vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_new_name = gfn_verify_string(vr_new_name)
	SET vr_new_description = gfn_verify_string(vr_new_description)
	
	UPDATE dct_tree_nodes
		SET Name = (CASE WHEN COALESCE(vr_new_name, N'') = N'' THEN Name ELSE vr_new_name END),
			description = vr_new_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND TreeNodeID = vr_tree_node_id
	
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_p_get_tree_node_hierarchy;

CREATE PROCEDURE dct_p_get_tree_node_hierarchy
	vr_application_id	UUID,
	vr_tree_node_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_id UUID = (
		SELECT TOP(1) TreeID 
		FROM dct_tree_nodes 
		WHERE ApplicationID = vr_application_id AND TreeNodeID = vr_tree_node_id
	)
 	
	;WITH hierarchy (ID, ParentID, level, Name)
 AS 
	(
		SELECT TreeNodeID AS id, ParentNodeID AS parent_id, 0 AS level, Name
		FROM dct_tree_nodes
		WHERE ApplicationID = vr_application_id AND TreeNodeID = vr_tree_node_id
		
		UNION ALL
		
		SELECT node.tree_node_id AS id, node.parent_node_id AS parent_id, level + 1, node.name
		FROM dct_tree_nodes AS node
			INNER JOIN hierarchy AS hr
			ON node.tree_node_id = hr.parent_id
		WHERE node.application_id = vr_application_id AND 
			node.tree_id = vr_tree_id AND node.tree_node_id <> hr.id AND node.deleted = FALSE
	)
	
	SELECT * 
	FROM hierarchy
	ORDER BY hierarchy.level ASC
END;


DROP PROCEDURE IF EXISTS dct_copy_trees_or_tree_nodes;

CREATE PROCEDURE dct_copy_trees_or_tree_nodes
	vr_application_id		UUID,
    vr_tree_idOrTreeNodeID	UUID,
    vr_strCopiedIDs		varchar(max),
    vr_delimiter			char,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_copied_ids GuidTableType
	
	INSERT INTO vr_copied_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strCopiedIDs, vr_delimiter) AS ref
	
	DECLARE vr_tbl TABLE (ID UUID, Name VARCHAR(500), 
		ParentID UUID, new_id UUID, level INTEGER, Seq INTEGER)
	
	INSERT INTO vr_tbl (ID, Name, ParentID, new_id, level, Seq)
	SELECT ref.node_id, ref.name, ref.parent_id, gen_random_uuid(), ref.level, ref.sequence_number
	FROM dct_fn_get_child_nodes_hierarchy(vr_application_id, vr_copied_ids, 0) AS ref
	
	DECLARE vr_tree_id UUID = NULL
	DECLARE vr_tree_node_id UUID = NULL
	
	SELECT vr_tree_id = t.tree_id
	FROM dct_trees AS t
	WHERE t.application_id = vr_application_id AND t.tree_id = vr_tree_idOrTreeNodeID
	
	SELECT vr_tree_id = tn.tree_id, vr_tree_node_id = tn.tree_node_id
	FROM dct_tree_nodes AS tn
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_idOrTreeNodeID
	
	IF vr_tree_id IS NULL BEGIN
		SELECT CAST(NULL AS uuid) AS id
		SELECT -1
		RETURN
	END
	
	DECLARE vr_rootSeq INTEGER = 1 + COALESCE((
		SELECT MAX(tn.sequence_number) + COUNT(tn.tree_node_id)
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND
			(
				(vr_tree_node_id IS NULL AND tn.parent_node_id IS NULL) OR
				tn.parent_node_id = vr_tree_node_id
			)
	), 0)
	
	UPDATE X
		SET Seq = ref.row_number + vr_rootSeq
	FROM vr_tbl AS x
		INNER JOIN (
			SELECT	ROW_NUMBER() OVER(ORDER BY 
						COALESCE(t.sequence_number, 10000) ASC, 
						t.name ASC,
						COALESCE(nd.seq, 10000) ASC,
						nd.name ASC,
						tn.creation_date ASC
					) AS row_number,
					tn.tree_node_id
			FROM vr_tbl AS nd
				INNER JOIN dct_tree_nodes AS tn
				ON tn.application_id = vr_application_id AND tn.tree_node_id = nd.id
				INNER JOIN dct_trees AS t
				ON t.application_id = vr_application_id AND t.tree_id = tn.tree_id
			WHERE nd.level = 0
		) AS ref
		ON ref.tree_node_id = x.id
	
	INSERT INTO dct_tree_nodes(
		ApplicationID,
		TreeNodeID,
		TreeID,
		Name,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, t.new_id, vr_tree_id, t.name, t.seq, vr_current_user_id, vr_now, 0
	FROM vr_tbl AS t
	
	UPDATE TN
		SET ParentNodeID = CASE WHEN node.level = 0 THEN vr_tree_node_id ELSE parent.new_id END
	FROM vr_tbl AS node
		LEFT JOIN vr_tbl AS parent
		ON parent.id = node.parent_id
		INNER JOIN dct_tree_nodes AS tn
		ON tn.application_id = vr_application_id AND tn.tree_node_id = node.new_id
	
    SELECT t.new_id AS id
    FROM vr_tbl AS t
    WHERE t.level = 0
END;


DROP PROCEDURE IF EXISTS dct_move_trees_or_tree_nodes;

CREATE PROCEDURE dct_move_trees_or_tree_nodes
	vr_application_id		UUID,
    vr_tree_idOrTreeNodeID	UUID,
    vr_strMovedIDs		varchar(max),
    vr_delimiter			char,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_moved_ids GuidTableType
	
	INSERT INTO vr_moved_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strMovedIDs, vr_delimiter) AS ref
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM vr_moved_ids AS m
		WHERE m.value = vr_tree_idOrTreeNodeID
	) BEGIN
		SELECT CAST(NULL AS uuid) AS id
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	DECLARE vr_tbl TABLE (ID UUID, Name VARCHAR(500), 
		ParentID UUID, level INTEGER, Seq INTEGER)
	
	INSERT INTO vr_tbl (ID, Name, ParentID, level, Seq)
	SELECT ref.node_id, ref.name, ref.parent_id, ref.level, ref.sequence_number
	FROM dct_fn_get_child_nodes_hierarchy(vr_application_id, vr_moved_ids, NULL) AS ref
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM vr_tbl AS t
		WHERE t.id = vr_tree_idOrTreeNodeID
	) BEGIN
		SELECT CAST(NULL AS uuid) AS id
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	DECLARE vr_tree_id UUID = NULL
	DECLARE vr_tree_node_id UUID = NULL
	
	SELECT vr_tree_id = t.tree_id
	FROM dct_trees AS t
	WHERE t.application_id = vr_application_id AND t.tree_id = vr_tree_idOrTreeNodeID
	
	SELECT vr_tree_id = tn.tree_id, vr_tree_node_id = tn.tree_node_id
	FROM dct_tree_nodes AS tn
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_idOrTreeNodeID
	
	IF vr_tree_id IS NULL BEGIN
		SELECT CAST(NULL AS uuid) AS id
		SELECT -1
		RETURN
	END
	
	DECLARE vr_rootSeq INTEGER = 1 + COALESCE((
		SELECT MAX(tn.sequence_number) + COUNT(tn.tree_node_id)
		FROM dct_tree_nodes AS tn
		WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND
			(
				(vr_tree_node_id IS NULL AND tn.parent_node_id IS NULL) OR
				tn.parent_node_id = vr_tree_node_id
			)
	), 0)
	
	UPDATE X
		SET Seq = ref.row_number + vr_rootSeq
	FROM vr_tbl AS x
		INNER JOIN (
			SELECT	ROW_NUMBER() OVER(ORDER BY 
						COALESCE(t.sequence_number, 10000) ASC, 
						t.name ASC,
						COALESCE(nd.seq, 10000) ASC,
						nd.name ASC,
						tn.creation_date ASC
					) AS row_number,
					tn.tree_node_id
			FROM vr_tbl AS nd
				INNER JOIN dct_tree_nodes AS tn
				ON tn.application_id = vr_application_id AND tn.tree_node_id = nd.id
				INNER JOIN dct_trees AS t
				ON t.application_id = vr_application_id AND t.tree_id = tn.tree_id
			WHERE nd.level = 0
		) AS ref
		ON ref.tree_node_id = x.id
	
	UPDATE TN
		SET TreeID = vr_tree_id,
			ParentNodeID = CASE WHEN node.level = 0 THEN vr_tree_node_id ELSE ParentNodeID END,
			SequenceNumber = CASE WHEN node.level = 0 THEN node.seq ELSE SequenceNumber END,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_tbl AS node
		INNER JOIN dct_tree_nodes AS tn
		ON tn.application_id = vr_application_id AND tn.tree_node_id = node.id
		
	UPDATE T
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_moved_ids AS i_ds
		INNER JOIN dct_trees AS t
		ON t.application_id = vr_application_id AND t.tree_id = i_ds.value
	
    SELECT t.id AS id
    FROM vr_tbl AS t
    WHERE t.level = 0
END;


DROP PROCEDURE IF EXISTS dct_move_tree_node;

CREATE PROCEDURE dct_move_tree_node
	vr_application_id			UUID,
    vr_strTreeNodeIDs			varchar(max),
	vr_delimiter				char,
    vr_new_parent_node_id		UUID,
    vr_last_modifier_user_id		UUID,
    vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids GuidTableType
	INSERT INTO vr_tree_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strTreeNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_parent_hierarchy NodesHierarchyTableType
	
	IF vr_new_parent_node_id IS NOT NULL BEGIN
		INSERT INTO vr_parent_hierarchy
		EXEC dct_p_get_tree_node_hierarchy vr_application_id, vr_new_parent_node_id
	END
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM vr_parent_hierarchy AS p
			INNER JOIN vr_tree_node_ids AS n
			ON n.value = p.node_id
	) BEGIN
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	UPDATE TN
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
			ParentNodeID = vr_new_parent_node_id
	FROM vr_tree_node_ids AS ref
		INNER JOIN dct_tree_nodes AS tn
		ON tn.tree_node_id = ref.value
	WHERE tn.application_id = vr_application_id AND 
		(vr_new_parent_node_id IS NULL OR tn.tree_node_id <> vr_new_parent_node_id)
	
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_p_remove_tree_nodes;

CREATE PROCEDURE dct_p_remove_tree_nodes
	vr_application_id		UUID,
    vr_tree_node_idsTemp	GuidTableType readonly,
    vr_tree_owner_id		UUID,
    vr_remove_hierarchy BOOLEAN,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP,
    vr__result		 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids GuidTableType
	INSERT INTO vr_tree_node_ids SELECT * FROM vr_tree_node_idsTemp
	
	IF COALESCE(vr_remove_hierarchy, 0) = 0 BEGIN
		UPDATE TN
			SET deleted = TRUE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		FROM vr_tree_node_ids AS ref
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND 
				tn.tree_node_id = ref.value AND tn.deleted = FALSE
			INNER JOIN dct_trees AS t
			ON t.application_id = vr_application_id AND t.tree_id = tn.tree_id AND
				((vr_tree_owner_id IS NULL AND t.owner_id IS NULL) OR t.owner_id = vr_tree_owner_id)
			
		SET vr__result = @vr_rowcount
		
		UPDATE TN
			SET ParentNodeID = NULL,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		FROM dct_tree_nodes AS tn
			INNER JOIN dct_trees AS t
			ON t.application_id = vr_application_id AND t.tree_id = tn.tree_id AND
				((vr_tree_owner_id IS NULL AND t.owner_id IS NULL) OR t.owner_id = vr_tree_owner_id)
		WHERE tn.application_id = vr_application_id AND 
			tn.parent_node_id IN(SELECT * FROM vr_tree_node_ids) AND tn.deleted = FALSE
		
		SET vr__result = MAX(@vr_rowcount + vr__result)
	END
	ELSE BEGIN
		UPDATE TN
			SET deleted = TRUE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		FROM dct_fn_get_child_nodes_hierarchy(vr_application_id, vr_tree_node_ids, 0) AS ref
			INNER JOIN dct_tree_nodes AS tn
			ON tn.application_id = vr_application_id AND 
				tn.tree_node_id = ref.node_id AND tn.deleted = FALSE
			INNER JOIN dct_trees AS t
			ON t.application_id = vr_application_id AND t.tree_id = tn.tree_id AND
				((vr_tree_owner_id IS NULL AND t.owner_id IS NULL) OR t.owner_id = vr_tree_owner_id)
			
		SET vr__result = @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS dct_arithmetic_delete_tree_node;

CREATE PROCEDURE dct_arithmetic_delete_tree_node
	vr_application_id		UUID,
    vr_strTreeNodeIDs		varchar(max),
    vr_delimiter			char,
    vr_tree_owner_id		UUID,
    vr_remove_hierarchy BOOLEAN,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids GuidTableType
	
	INSERT INTO vr_tree_node_ids
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strTreeNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr__result INTEGER = 0
	
	EXEC dct_p_remove_tree_nodes vr_application_id, vr_tree_node_ids, vr_tree_owner_id, 
		vr_remove_hierarchy, vr_current_user_id, vr_now, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS dct_p_get_tree_nodes_by_ids;

CREATE PROCEDURE dct_p_get_tree_nodes_by_ids
	vr_application_id		UUID,
    vr_tree_node_idsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids KeyLessGuidTableType
	INSERT INTO vr_tree_node_ids (Value) SELECT Value FROM vr_tree_node_idsTemp
	
	SELECT tn.tree_node_id AS tree_node_id,
		   tn.tree_id AS tree_id,
		   tn.parent_node_id AS parent_node_id,
		   tn.name AS name,
		   (
				SELECT CAST(1 AS boolean) 
				WHERE EXISTS(
						SELECT TOP(1)* 
						FROM dct_tree_nodes AS tn
						WHERE tn.application_id = vr_application_id AND 
							tn.parent_node_id = ref.value AND tn.deleted = FALSE
					)
			) AS has_child
	FROM vr_tree_node_ids AS ref
		INNER JOIN dct_tree_nodes AS tn
		ON tn.tree_node_id = ref.value
	WHERE tn.application_id = vr_application_id AND tn.deleted = FALSE
	ORDER BY ref.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS dct_get_tree_nodes_by_ids;

CREATE PROCEDURE dct_get_tree_nodes_by_ids
	vr_application_id		UUID,
    vr_strTreeNodeIDs		varchar(max),
    vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids KeyLessGuidTableType
	
	INSERT INTO vr_tree_node_ids (Value)
	SELECT DISTINCT ref.value 
	FROM GFN_StrToGuidTable(vr_strTreeNodeIDs, vr_delimiter) AS ref
	
	EXEC dct_p_get_tree_nodes_by_ids vr_application_id, vr_tree_node_ids
END;



DROP PROCEDURE IF EXISTS dct_get_tree_nodes;

CREATE PROCEDURE dct_get_tree_nodes
	vr_application_id	UUID,
    vr_tree_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids KeyLessGuidTableType
	
	INSERT INTO vr_tree_node_ids (Value)
	SELECT TreeNodeID
	FROM dct_tree_nodes
	WHERE ApplicationID = vr_application_id AND TreeID = vr_tree_id AND deleted = FALSE
	ORDER BY COALESCE(SequenceNumber, 100000) ASC, Name ASC, CreationDate ASC
	
	EXEC dct_p_get_tree_nodes_by_ids vr_application_id, vr_tree_node_ids
END;


DROP PROCEDURE IF EXISTS dct_get_root_nodes;

CREATE PROCEDURE dct_get_root_nodes
	vr_application_id	UUID,
    vr_tree_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids KeyLessGuidTableType
	
	INSERT INTO vr_tree_node_ids (Value)
	SELECT TreeNodeID
	FROM dct_tree_nodes
	WHERE ApplicationID = vr_application_id AND TreeID = vr_tree_id AND deleted = FALSE AND 
		(ParentNodeID IS NULL OR ParentNodeID = TreeNodeID)
	ORDER BY COALESCE(SequenceNumber, 100000) ASC, Name ASC, CreationDate ASC
	
	EXEC dct_p_get_tree_nodes_by_ids vr_application_id, vr_tree_node_ids
END;


DROP PROCEDURE IF EXISTS dct_get_child_nodes;

CREATE PROCEDURE dct_get_child_nodes
	vr_application_id	UUID,
    vr_parent_node_id	UUID,
    vr_tree_id			UUID,
    vr_searchText	 VARCHAR(500)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_tree_id IS NULL AND vr_parent_node_id IS NULL RETURN
	
	DECLARE vr_tree_node_ids KeyLessGuidTableType
	
	IF COALESCE(vr_searchText, N'') = N'' BEGIN
		INSERT INTO vr_tree_node_ids (Value)
		SELECT TreeNodeID
		FROM dct_tree_nodes
		WHERE ApplicationID = vr_application_id AND deleted = FALSE AND 
			(vr_tree_id IS NULL OR TreeID = vr_tree_id) AND
			(
				(vr_parent_node_id IS NULL AND ParentNodeID IS NULL) OR 
				(vr_parent_node_id IS NOT NULL AND ParentNodeID = vr_parent_node_id)
			)
		ORDER BY COALESCE(SequenceNumber, 100000) ASC, Name ASC, CreationDate ASC
	END
	ELSE BEGIN
		DECLARE vr_iDs GuidTableType
	
		IF vr_parent_node_id IS NOT NULL BEGIN
			INSERT INTO vr_iDs (Value)
			VALUES (vr_parent_node_id)
			
			INSERT INTO vr_iDs (Value)
			SELECT DISTINCT h.node_id
			FROM dct_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_iDs) AS h
			WHERE h.node_id <> vr_parent_node_id
			
			DELETE vr_iDs
			WHERE Value = vr_parent_node_id
		END
		
		DECLARE vr_node_idsCount INTEGER = (SELECT COUNT(*) FROM vr_iDs)
	
		INSERT INTO vr_tree_node_ids (Value)
		SELECT x.node_id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key ASC) AS row_number,
						srch.key AS node_id
				FROM CONTAINSTABLE(dct_tree_nodes, (Name), vr_searchText) AS srch
					INNER JOIN dct_tree_nodes AS tn
					ON tn.tree_node_id = srch.key
					LEFT JOIN vr_iDs AS i
					ON i.value = tn.tree_node_id
				WHERE tn.application_id = vr_application_id AND tn.deleted = FALSE AND 
					(vr_node_idsCount = 0 OR i.value IS NOT NULL) AND 
					(vr_tree_id IS NULL OR tn.tree_id = vr_tree_id)
			) AS x
		ORDER BY x.row_number ASC
	END
	
	EXEC dct_p_get_tree_nodes_by_ids vr_application_id, vr_tree_node_ids
END;


DROP PROCEDURE IF EXISTS dct_get_parent_node;

CREATE PROCEDURE dct_get_parent_node
	vr_application_id	UUID,
    vr_tree_node_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids KeyLessGuidTableType
	
	INSERT INTO vr_tree_node_ids (Value)
	SELECT first.parent_node_id
	FROM dct_tree_nodes AS first 
		INNER JOIN dct_tree_nodes AS second
		ON second.application_id = vr_application_id AND 
			second.tree_node_id = first.parent_node_id
	WHERE first.application_id = vr_application_id AND 
		first.tree_node_id = vr_tree_node_id AND second.deleted = FALSE
	
	EXEC dct_p_get_tree_nodes_by_ids vr_application_id, vr_tree_node_ids
END;


DROP PROCEDURE IF EXISTS dct_p_add_files;

CREATE PROCEDURE dct_p_add_files
	vr_application_id	UUID,
    vr_owner_id		UUID,
    vr_owner_type		varchar(20),
    vr_doc_files_temp	DocFileInfoTableType readonly,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_doc_files DocFileInfoTableType
	INSERT INTO vr_doc_files SELECT * FROM vr_doc_files_temp
	
	UPDATE D
		SET deleted = FALSE
	FROM vr_doc_files AS f
		INNER JOIN dct_files AS d
		ON d.application_id = vr_application_id AND (d.id = f.file_id OR d.file_name_guid = f.file_id) AND
			((f.owner_id IS NULL AND d.owner_id IS NULL) OR (d.owner_id = COALESCE(vr_owner_id, f.owner_id)))
	
	INSERT INTO dct_files (
		ApplicationID,
		ID,
		OwnerID,
		OwnerType,
		FileNameGuid,
		Extension,
		file_name,
		MIME,
		Size,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	vr_application_id, 
			gen_random_uuid(),
			COALESCE(vr_owner_id, f.owner_id),
			COALESCE(vr_owner_type, f.owner_type),
			f.file_id,
			f.extension,
			f.file_name,
			f.mime,
			f.size,
			vr_current_user_id,
			vr_now,
			0
	FROM vr_doc_files AS f
		LEFT JOIN dct_files AS d
		ON d.application_id = vr_application_id AND (d.id = f.file_id OR d.file_name_guid = f.file_id) AND
			((f.owner_id IS NULL AND d.owner_id IS NULL) OR (d.owner_id = COALESCE(vr_owner_id, f.owner_id)))
	WHERE d.id IS NULL
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_add_files;

CREATE PROCEDURE dct_add_files
	vr_application_id	UUID,
    vr_owner_id		UUID,
    vr_owner_type		varchar(50),
    vr_doc_files_temp	DocFileInfoTableType readonly,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_doc_files DocFileInfoTableType
	INSERT INTO vr_doc_files SELECT * FROM vr_doc_files_temp
	
	DECLARE vr__result INTEGER
	
	EXEC dct_p_add_files vr_application_id, vr_owner_id, vr_owner_type, vr_doc_files,
		vr_current_user_id, vr_now, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS dct_p_remove_owner_files;

CREATE PROCEDURE dct_p_remove_owner_files
	vr_application_id	UUID,
    vr_owner_id		UUID,
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM dct_files
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	) BEGIN
		UPDATE dct_files
			SET deleted = TRUE
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
		
		SET vr__result = @vr_rowcount
	END
	ELSE BEGIN
		SET vr__result = 1
	END
END;


DROP PROCEDURE IF EXISTS dct_p_remove_owners_files;

CREATE PROCEDURE dct_p_remove_owners_files
	vr_application_id	UUID,
    vr_owner_idsTemp	GuidTableType readonly,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids SELECT * FROM vr_owner_idsTemp
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM vr_owner_ids AS i_ds
			INNER JOIN dct_files AS f
			ON f.application_id = vr_application_id AND f.owner_id = i_ds.value AND f.deleted = FALSE
	) BEGIN
		UPDATE F
			SET deleted = TRUE
		FROM vr_owner_ids AS i_ds
			INNER JOIN dct_files AS f
			ON f.application_id = vr_application_id AND f.owner_id = i_ds.value AND f.deleted = FALSE
		
		SET vr__result = @vr_rowcount
	END
	ELSE BEGIN
		SET vr__result = 1
	END
END;


DROP PROCEDURE IF EXISTS dct_rename_file;

CREATE PROCEDURE dct_rename_file
	vr_application_id	UUID,
    vr_file_id			UUID,
    vr_name		 VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE AF
		SET file_name = gfn_verify_string(COALESCE(vr_name, N'file'))
	FROM dct_files AS af
	WHERE af.application_id = vr_application_id AND  (af.id = vr_file_id OR af.file_name_guid = vr_file_id)
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_arithmetic_delete_files;

CREATE PROCEDURE dct_arithmetic_delete_files
	vr_application_id	UUID,
	vr_owner_id		UUID,
    vr_strFileIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_file_ids GuidTableType
	INSERT INTO vr_file_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strFileIDs, vr_delimiter) AS ref
	
	IF vr_owner_id IS NULL BEGIN
		UPDATE AF
			SET deleted = TRUE
		FROM vr_file_ids AS external_ids
			INNER JOIN dct_files AS af
			ON af.application_id = vr_application_id AND 
				(af.id = external_ids.value OR af.file_name_guid = external_ids.value)
	END
	ELSE BEGIN
		UPDATE AF
			SET deleted = TRUE
		FROM vr_file_ids AS external_ids
			INNER JOIN dct_files AS af
			ON af.id = external_ids.value OR af.file_name_guid = external_ids.value
		WHERE af.application_id = vr_application_id AND af.owner_id = vr_owner_id AND af.deleted = FALSE
	END
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_copy_file;

CREATE PROCEDURE dct_copy_file
	vr_application_id	UUID,
	vr_owner_id		UUID,
    vr_file_id			UUID,
    vr_owner_type		varchar(50),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM dct_files AS af
		WHERE af.application_id = vr_application_id AND 
			af.owner_id = vr_owner_id AND (af.id = vr_file_id OR af.file_name_guid = vr_file_id)
	) BEGIN
		UPDATE AF
			SET deleted = FALSE
		FROM dct_files AS af
		WHERE af.application_id = vr_application_id AND 
			af.owner_id = vr_owner_id AND (af.id = vr_file_id OR af.file_name_guid = vr_file_id)
		
		SELECT @vr_rowcount
	END
	ELSE BEGIN
		INSERT INTO dct_files (
			ApplicationID,
			ID,
			OwnerID,
			OwnerType,
			FileNameGuid,
			Extension,
			file_name,
			MIME,
			Size,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT TOP(1) 
			vr_application_id, 
			gen_random_uuid(), 
			vr_owner_id,
			vr_owner_type,
			af.file_name_guid, 
			af.extension, 
			af.file_name, 
			af.mime, 
			af.size, 
			vr_current_user_id,
			vr_now,
			0
		FROM dct_files AS af
		WHERE af.application_id = vr_application_id AND 
			(af.id = vr_file_id OR af.file_name_guid = vr_file_id)
	
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS dct_p_copy_attachments;

CREATE PROCEDURE dct_p_copy_attachments
	vr_application_id	UUID,
	vr_from_owner_id	UUID,
    vr_to_owner_id		UUID,
    vr_to_owner_type	varchar(50),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO dct_files (
		ApplicationID,
		ID,
		OwnerID,
		OwnerType,
		FileNameGuid,
		Extension,
		file_name,
		MIME,
		Size,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	vr_application_id,
			gen_random_uuid(),
			vr_to_owner_id,
			vr_to_owner_type,
			af.file_name_guid,
			af.extension,
			af.file_name,
			af.mime,
			af.size,
			vr_current_user_id,
			vr_now,
			af.deleted
	FROM dct_files AS af
	WHERE af.application_id = vr_application_id AND af.owner_id = vr_from_owner_id AND af.deleted = FALSE
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_p_get_files_by_ids;

CREATE PROCEDURE dct_p_get_files_by_ids
	vr_application_id	UUID,
    vr_file_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_file_ids GuidTableType
	INSERT INTO vr_file_ids SELECT * FROM vr_file_idsTemp
	
	SELECT af.owner_id,
		   af.owner_type,
		   af.file_name_guid AS file_id,
		   af.file_name,
		   af.extension,
		   af.mime,
		   af.size
	FROM vr_file_ids AS external_ids
		INNER JOIN dct_files AS af
		ON af.application_id = vr_application_id AND 
			external_ids.value = af.id OR external_ids.value = af.file_name_guid
	ORDER BY af.creation_date ASC, af.file_name ASC
END;


DROP PROCEDURE IF EXISTS dct_get_owner_files;

CREATE PROCEDURE dct_get_owner_files
	vr_application_id	UUID,
    vr_strOwnerIDs	varchar(max),
    vr_delimiter		char,
    vr_type			varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strOwnerIDs, vr_delimiter) AS ref
	
	DECLARE vr_file_ids GuidTableType
	
	INSERT INTO vr_file_ids
	SELECT af.id
	FROM vr_owner_ids AS external_ids
		INNER JOIN dct_files AS af
		ON af.application_id = vr_application_id AND 
			af.owner_id = external_ids.value AND af.deleted = FALSE AND
			(vr_type IS NULL OR af.owner_type = vr_type)
		
	EXEC dct_p_get_files_by_ids vr_application_id, vr_file_ids
END;


DROP PROCEDURE IF EXISTS dct_get_files_by_ids;

CREATE PROCEDURE dct_get_files_by_ids
	vr_application_id	UUID,
    vr_strFileIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_file_ids GuidTableType
	INSERT INTO vr_file_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strFileIDs, vr_delimiter) AS ref
	
	EXEC dct_p_get_files_by_ids vr_application_id, vr_file_ids
END;


DROP PROCEDURE IF EXISTS dct_get_file_owner_nodes;

CREATE PROCEDURE dct_get_file_owner_nodes
	vr_application_id	UUID,
	vr_strFileIDs		varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs GuidTableType
	
	INSERT INTO vr_iDs (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strFileIDs, vr_delimiter) AS ref
	
	SELECT ref.file_id, ref.node_id, ref.node_name AS name, ref.node_type
	FROM dct_fn_get_file_owner_nodes(vr_application_id, vr_iDs) AS ref
END;


DROP PROCEDURE IF EXISTS dct_get_not_extracted_files;

CREATE PROCEDURE dct_get_not_extracted_files
	vr_application_id		UUID,
	vr_allowedExtensions	varchar(max),
	vr_delimiter			char,
	vr_count			 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_ext stringTableType
	
	INSERT INTO vr_ext 
	SELECT LOWER(ref.value) 
	FROM dbo.g_fn_str_to_string_table(vr_allowedExtensions,vr_delimiter) AS ref
	
	DECLARE vr_file_ids GuidTableType
	
	INSERT INTO vr_file_ids (Value)
	SELECT TOP (COALESCE(vr_count, 20)) af.id
	FROM vr_ext AS ex
		INNER JOIN dct_files AS af
		ON ex.value = LOWER(af.extension)
		LEFT JOIN dct_file_contents AS fc
		ON fc.application_id = vr_application_id AND fc.file_id = af.file_name_guid
	WHERE af.application_id = vr_application_id AND af.deleted = FALSE AND fc.file_id IS NULL AND 
		(af.owner_type = N'Node' OR af.owner_type = N'WikiContent' OR 
			af.owner_type = N'FormElement')
		
	EXEC dct_p_get_files_by_ids vr_application_id, vr_file_ids
END;


DROP PROCEDURE IF EXISTS dct_save_file_content;

CREATE PROCEDURE dct_save_file_content
	vr_application_id	UUID,
	vr_file_id			UUID,
	vr_content	 VARCHAR(MAX),
	vr_not_extractable BOOLEAN,
	vr_file_not_fount BOOLEAN,
	vr_duration		BIGINT,
	vr_extractionDate TIMESTAMP,
	vr_error		 VARCHAR(MAX)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_content = gfn_verify_string(COALESCE(vr_content, N''))
	
    INSERT INTO DCT_FileContents (
		ApplicationID,
		FileID, 
		Content, 
		NotExtractable,
		FileNotFound, 
		Duration, 
		ExtractionDate, 
		Error
	)
    VALUES (vr_application_id, vr_file_id, vr_content, vr_not_extractable, vr_file_not_fount, 
		vr_duration , vr_extractionDate, vr_error)
    
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_get_tree_node_hierarchy;

CREATE PROCEDURE dct_get_tree_node_hierarchy
	vr_application_id	UUID,
	vr_tree_node_id		UUID
WITH ENCRYPTION
AS
BEGIN
	WITH hierarchy (ID, ParentID, level, Name)
 AS 
	(
		SELECT TreeNodeID AS id, ParentNodeID, 0 AS level, Name
		FROM dct_tree_nodes
		WHERE ApplicationID = vr_application_id AND TreeNodeID = vr_tree_node_id
		
		UNION ALL
		
		SELECT tn.tree_node_id AS id, tn.parent_node_id, level + 1, tn.name
		FROM dct_tree_nodes AS tn
			INNER JOIN hierarchy AS hr
			ON tn.tree_node_id = hr.parent_id
		WHERE tn.application_id = vr_application_id AND tn.tree_node_id <> hr.id AND tn.deleted = FALSE
	)
	
	SELECT * FROM hierarchy
END;


DROP PROCEDURE IF EXISTS dct_set_tree_nodes_order;

CREATE PROCEDURE dct_set_tree_nodes_order
	vr_application_id	UUID,
	vr_strTreeNodeIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_node_ids TABLE (
		SequenceNo INTEGER identity(1, 1) primary key, 
		TreeNodeID UUID
	)
	
	INSERT INTO vr_tree_node_ids (TreeNodeID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strTreeNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_parent_node_id UUID = NULL, vr_tree_id UUID = NULL
	
	SELECT TOP(1) vr_parent_node_id = ParentNodeID, vr_tree_id = TreeID
	FROM dct_tree_nodes
	WHERE ApplicationID = vr_application_id AND 
		TreeNodeID = (SELECT TOP (1) ref.tree_node_id FROM vr_tree_node_ids AS ref)
	
	INSERT INTO vr_tree_node_ids (TreeNodeID)
	SELECT tn.tree_node_id
	FROM vr_tree_node_ids AS ref
		RIGHT JOIN dct_tree_nodes AS tn
		ON tn.application_id = vr_application_id AND tn.tree_node_id = ref.tree_node_id
	WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND (
			(tn.parent_node_id IS NULL AND vr_parent_node_id IS NULL) OR 
			tn.parent_node_id = vr_parent_node_id
		) AND ref.tree_node_id IS NULL
	ORDER BY tn.sequence_number
	
	UPDATE dct_tree_nodes
		SET SequenceNumber = ref.sequence_no
	FROM vr_tree_node_ids AS ref
		INNER JOIN dct_tree_nodes AS tn
		ON tn.tree_node_id = ref.tree_node_id
	WHERE tn.application_id = vr_application_id AND tn.tree_id = vr_tree_id AND (
			(tn.parent_node_id IS NULL AND vr_parent_node_id IS NULL) OR 
			tn.parent_node_id = vr_parent_node_id
		)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_is_private_tree;

CREATE PROCEDURE dct_is_private_tree
	vr_application_id		UUID,
	vr_tree_idOrTreeNodeID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT CAST(1 AS boolean)
	WHERE EXISTS(
			SELECT TOP(1) TreeID
			FROM dct_trees
			WHERE ApplicationID = vr_application_id AND 
				TreeID = vr_tree_idOrTreeNodeID AND IsPrivate = 1
		) OR EXISTS(
			SELECT TOP(1) n.tree_node_id
			FROM dct_tree_nodes AS n
				INNER JOIN dct_trees AS t
				ON t.application_id = vr_application_id AND t.tree_id = n.tree_id
			WHERE n.application_id = vr_application_id AND 
				n.tree_node_id = vr_tree_idOrTreeNodeID AND t.is_private = 1
		)
END;


DROP PROCEDURE IF EXISTS dct_add_owner_tree;

CREATE PROCEDURE dct_add_owner_tree
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_tree_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM dct_tree_owners
		WHERE ApplicationID = vr_application_id AND
			OwnerID = vr_owner_id AND TreeID = vr_tree_id
	) BEGIN
		UPDATE dct_tree_owners
			SET deleted = FALSE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		WHERE ApplicationID = vr_application_id AND 
			OwnerID = vr_owner_id AND TreeID = vr_tree_id
	END
	ELSE BEGIN
		INSERT INTO dct_tree_owners(
			ApplicationID,
			OwnerID,
			TreeID,
			UniqueID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_owner_id,
			vr_tree_id,
			gen_random_uuid(),
			vr_current_user_id,
			vr_now,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_arithmetic_delete_owner_tree;

CREATE PROCEDURE dct_arithmetic_delete_owner_tree
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_tree_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE dct_tree_owners
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND 
		OwnerID = vr_owner_id AND TreeID = vr_tree_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_get_tree_owner_id;

CREATE PROCEDURE dct_get_tree_owner_id
	vr_application_id		UUID,
	vr_tree_idOrTreeNodeID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_tree_idOrTreeNodeID = COALESCE((
		SELECT TOP(1) TreeID
		FROM dct_tree_nodes
		WHERE ApplicationID = vr_application_id AND TreeNodeID = vr_tree_idOrTreeNodeID
	), vr_tree_idOrTreeNodeID)
	
	SELECT TOP(1) OwnerID AS id
	FROM dct_trees
	WHERE TreeID = vr_tree_idOrTreeNodeID
END;


DROP PROCEDURE IF EXISTS dct_get_owner_trees;

CREATE PROCEDURE dct_get_owner_trees
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_tree_ids GuidTableType
	
	INSERT INTO vr_tree_ids
	SELECT TreeID
	FROM dct_tree_owners
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	
	EXEC dct_p_get_trees_by_ids vr_application_id, vr_tree_ids
END;


DROP PROCEDURE IF EXISTS dct_clone_trees;

CREATE PROCEDURE dct_clone_trees
	vr_application_id	UUID,
	vr_strTreeIDs		varchar(max),
	vr_delimiter		char,
	vr_owner_id		UUID,
	vr_allowMultiple BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tree_ids TABLE (
		TreeID UUID, 
		TreeID_New UUID,
		AlreadyCreated BOOLEAN,
		Seq INTEGER IDENTITY(1, 1)
	)

	INSERT INTO vr_tree_ids (TreeID, TreeID_New, AlreadyCreated)
	SELECT	ref.value, 
			COALESCE(t.tree_id, gen_random_uuid()), 
			CASE WHEN t.tree_id IS NULL THEN 0 ELSE 1 END
	FROM gfn_str_to_guid_table(vr_strTreeIDs, vr_delimiter) AS ref
		LEFT JOIN dct_trees AS t
		ON t.application_id = vr_application_id AND t.owner_id = vr_owner_id AND 
			t.ref_tree_id = ref.value AND COALESCE(vr_allowMultiple, 0) = 0

	INSERT INTO dct_trees (
		ApplicationID,
		TreeID,
		RefTreeID,
		IsPrivate,
		OwnerID,
		Name,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	t.application_id, 
			id.tree_id_new, 
			id.tree_id, 
			CASE WHEN vr_owner_id IS NULL THEN 0 ELSE 1 END, 
			vr_owner_id, 
			t.name, 
			vr_current_user_id, 
			vr_now, 
			0
	FROM vr_tree_ids AS id
		INNER JOIN dct_trees AS t
		ON t.application_id = vr_application_id AND t.tree_id = id.tree_id
	WHERE id.already_created = 0

	DECLARE vr_tree_nodes TABLE (
		TreeID UUID, 
		ID UUID, 
		ParentID UUID,
		TreeID_New UUID, 
		ID_New UUID, 
		ParentID_New UUID
	)
		
	INSERT INTO vr_tree_nodes (TreeID, ID, ParentID, TreeID_New, ID_New)
	SELECT n.tree_id, n.tree_node_id, n.parent_node_id, id.tree_id_new, gen_random_uuid()
	FROM vr_tree_ids AS id
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND 
			n.tree_id = id.tree_id AND n.deleted = FALSE
	WHERE id.already_created = 0

	UPDATE T
		SET ParentID_New = p.i_d_new
	FROM vr_tree_nodes AS t
		INNER JOIN vr_tree_nodes AS p
		ON p.tree_id = t.tree_id AND p.id = t.parent_id

	INSERT INTO dct_tree_nodes (
		ApplicationID,
		TreeNodeID,
		TreeID,
		Name,
		CreatorUserID,
		CreationDate,
		SequenceNumber,
		Deleted
	)
	SELECT vr_application_id, t.i_d_new, t.tree_id_new, 
		n.name, vr_current_user_id, vr_now, n.sequence_number, 0
	FROM vr_tree_nodes AS t
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND n.tree_node_id = t.id

	UPDATE N
		SET ParentNodeID = t.parent_id_new
	FROM vr_tree_nodes AS t
		INNER JOIN dct_tree_nodes AS n
		ON n.application_id = vr_application_id AND n.tree_node_id = t.i_d_new
	WHERE t.parent_id_new IS NOT NULL AND t.i_d_new <> t.parent_id_new

	DECLARE vr_iDs GuidTableType
	
	INSERT INTO vr_iDs (Value)
	SELECT t.tree_id_new
	FROM vr_tree_ids AS t

	EXEC dct_p_get_trees_by_ids vr_application_id, vr_iDs
END;


DROP PROCEDURE IF EXISTS dct_p_add_tree_node_contents;

CREATE PROCEDURE dct_p_add_tree_node_contents
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_node_idsTemp	GuidTableType readonly,
	vr_remove_from		UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids SELECT * FROM vr_node_idsTemp

	IF vr_remove_from IS NOT NULL AND vr_remove_from <> vr_tree_node_id BEGIN
		UPDATE C
			SET deleted = TRUE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		FROM vr_node_ids AS i_ds
			INNER JOIN dct_tree_node_contents AS c
			ON c.application_id = vr_application_id AND c.tree_node_id = vr_remove_from AND 
				c.node_id = i_ds.value AND c.deleted = FALSE
	END
	
	UPDATE C
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_node_ids AS i_ds
		INNER JOIN dct_tree_node_contents AS c
		ON c.application_id = vr_application_id AND 
			c.tree_node_id = vr_tree_node_id AND c.node_id = i_ds.value
			
	INSERT INTO dct_tree_node_contents (
		ApplicationID,
		TreeNodeID,
		NodeID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, vr_tree_node_id, i_ds.value, vr_current_user_id, vr_now, 0
	FROM vr_node_ids AS i_ds
		LEFT JOIN dct_tree_node_contents AS c
		ON c.application_id = vr_application_id AND 
			c.tree_node_id = vr_tree_node_id AND c.node_id = i_ds.value
	WHERE c.tree_node_id IS NULL
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS dct_add_tree_node_contents;

CREATE PROCEDURE dct_add_tree_node_contents
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_strNodeIDs		varchar(max),
	vr_delimiter		char,
	vr_remove_from		UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr__result INTEGER = 0
	
	EXEC dct_p_add_tree_node_contents vr_application_id, vr_tree_node_id, vr_node_ids, 
		vr_remove_from, vr_current_user_id, vr_now, vr__result output
		
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS dct_p_remove_tree_node_contents;

CREATE PROCEDURE dct_p_remove_tree_node_contents
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_node_idsTemp	GuidTableType readonly,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids SELECT * FROM vr_node_idsTemp

	UPDATE C
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_node_ids AS i_ds
		INNER JOIN dct_tree_node_contents AS c
		ON c.application_id = vr_application_id AND 
			c.tree_node_id = vr_tree_node_id AND c.node_id = i_ds.value
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS dct_remove_tree_node_contents;

CREATE PROCEDURE dct_remove_tree_node_contents
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_strNodeIDs		varchar(max),
	vr_delimiter		char,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr__result INTEGER = 0
	
	EXEC dct_p_remove_tree_node_contents vr_application_id, vr_tree_node_id, 
		vr_node_ids, vr_current_user_id, vr_now, vr__result output
	
	SELECT vr__result
END;

DROP PROCEDURE IF EXISTS usr_get_users_count;

CREATE PROCEDURE usr_get_users_count
	vr_application_id				UUID,
	vr_creation_dateLowerThreshold TIMESTAMP,
	vr_creation_dateUpperThreshold TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT COUNT(ref.user_id)
	FROM users_normal AS ref
	WHERE ApplicationID = vr_application_id AND 
		(vr_creation_dateLowerThreshold IS NULL OR 
		ref.creation_date >= vr_creation_dateLowerThreshold) AND
		(vr_creation_dateUpperThreshold IS NULL OR 
		ref.creation_date <= vr_creation_dateUpperThreshold) AND ref.is_approved = TRUE
END;


DROP PROCEDURE IF EXISTS usr_get_user_ids;

CREATE PROCEDURE usr_get_user_ids
	vr_application_id	UUID,
    vr_usernamesTemp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_usernames StringTableType
	INSERT INTO vr_usernames SELECT * FROM vr_usernamesTemp
	
	IF vr_application_id IS NULL BEGIN
		SELECT un.user_id AS id
		FROM vr_usernames AS ref
			INNER JOIN usr_view_users AS un
			ON un.lowered_username = LOWER(ref.value)
	END
	ELSE BEGIN
		SELECT un.user_id AS id
		FROM vr_usernames AS ref
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.lowered_username = LOWER(ref.value)
	END
END;


DROP PROCEDURE IF EXISTS usr_p_get_users_by_ids;

CREATE PROCEDURE usr_p_get_users_by_ids
	vr_application_id	UUID,
    vr_user_idsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids KeyLessGuidTableType
	INSERT INTO vr_user_ids (Value) SELECT Value FROM vr_user_idsTemp

	IF vr_application_id IS NULL BEGIN
		SELECT	un.user_id, 
				un.username,
				un.first_name, 
				un.last_name, 
				un.birthdate,
				N'' AS about_me,
				N'' AS city,
				N'' AS organization,
				N'' AS department,
				N'' AS job_title,
				un.main_phone_id,
				un.main_email_id,
				un.is_approved, 
				un.is_locked_out
		FROM	vr_user_ids AS ref
				INNER JOIN usr_view_users AS un
				ON un.user_id = ref.value
	END
	ELSE BEGIN
		SELECT	un.user_id, 
				un.username,
				un.first_name, 
				un.last_name, 
				un.birthdate,
				un.about_me,
				un.city,
				un.organization,
				un.department,
				un.job_title,
				un.main_phone_id,
				un.main_email_id,
				un.is_approved, 
				un.is_locked_out
		FROM	vr_user_ids AS ref
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.value
	END
END;


DROP PROCEDURE IF EXISTS usr_get_users_by_ids;

CREATE PROCEDURE usr_get_users_by_ids
	vr_application_id	UUID,
	vr_strUserIDs 	varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids KeyLessGuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT ref.value FROM GFN_StrToGuidTable(vr_strUserIDs, vr_delimiter) AS ref
	
	EXEC usr_p_get_users_by_ids vr_application_id, vr_user_ids
END;


DROP PROCEDURE IF EXISTS usr_get_users_by_username;

CREATE PROCEDURE usr_get_users_by_username
	vr_application_id	UUID,
    vr_usernamesTemp	StringTableType readonly
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_usernames StringTableType
	INSERT INTO vr_usernames (Value)
	SELECT DISTINCT LOWER(t.value)
	FROM vr_usernamesTemp AS t
	
	DECLARE vr_user_ids KeyLessGuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT un.user_id
	FROM vr_usernames AS ref
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = ref.value
	
	EXEC usr_p_get_users_by_ids vr_application_id, vr_user_ids
END;


DROP PROCEDURE IF EXISTS usr_get_users;

CREATE PROCEDURE usr_get_users
	vr_application_id	UUID,
    vr_searchText  VARCHAR(1000),
    vr_lower_boundary	bigint,
    vr_count		 INTEGER,
    vr_isOnline	 BOOLEAN,
    vr_isApproved	 BOOLEAN,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_verify_string(vr_searchText)
	
	IF vr_count IS NULL SET vr_count = 20
	IF vr_isOnline IS NULL SET vr_isOnline = 0
	
	DECLARE vr_online_time_treshold TIMESTAMP = DATEADD(MINUTE, -1, vr_now)
	
	DECLARE vr_user_ids KeyLessGuidTableType
	
	DECLARE vr_tbl Table (UserID UUID, TotalCount bigint, RowNumber INTEGER)
	DECLARE vr_total_count bigint = 0
	
	IF vr_searchText IS NULL OR vr_searchText = '' BEGIN
		INSERT INTO vr_tbl (UserID, TotalCount, RowNumber)
		SELECT TOP(vr_count) u.user_id, (u.row_number + u.rev_row_number - 1) AS total_count, u.row_number
		FROM (	
				SELECT	ROW_NUMBER() OVER (ORDER BY un.creation_date DESC, un.user_id DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY un.creation_date ASC, un.user_id ASC) AS rev_row_number,
						un.user_id
				FROM users_normal AS un
				WHERE un.application_id = vr_application_id AND 
					(vr_isApproved IS NULL OR COALESCE(un.is_approved, TRUE) = vr_isApproved) AND
					(vr_isOnline = 0 OR un.last_activity_date >= vr_online_time_treshold)
			) AS u
		WHERE u.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY u.row_number ASC
	END
	ELSE BEGIN
		INSERT INTO vr_tbl (UserID, TotalCount, RowNumber)
		SELECT TOP(vr_count) u.user_id, (u.no + u.rev_no - 1) AS total_count, u.row_number
		FROM (	
				SELECT	
						ROW_NUMBER() OVER (ORDER BY srch.rank DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank DESC, un.user_id DESC) AS no,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, un.user_id ASC) AS rev_no,
						un.user_id
				FROM CONTAINSTABLE(usr_view_users , 
						(FirstName, LastName, UserName), vr_searchText) AS srch
					INNER JOIN users_normal AS un
					ON un.user_id = srch.key
				WHERE un.application_id = vr_application_id AND 
					(vr_isApproved IS NULL OR COALESCE(un.is_approved, TRUE) = vr_isApproved) AND
					(vr_isOnline = 0 OR un.last_activity_date >= vr_online_time_treshold)
			) AS u
		WHERE u.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY u.row_number ASC
	END
	
	INSERT INTO vr_user_ids (Value)
	SELECT t.user_id
	FROM vr_tbl AS t
	ORDER BY t.row_number ASC
	
	EXEC usr_p_get_users_by_ids vr_application_id, vr_user_ids
	
	SELECT TOP(1) t.total_count AS total_count
	FROM vr_tbl AS t
END;


DROP PROCEDURE IF EXISTS usr_get_application_users_partitioned;

CREATE PROCEDURE usr_get_application_users_partitioned
	vr_strApplicationIDs	varchar(max),
	vr_delimiter			char,
	vr_count			 INTEGER
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_application_ids GuidTableType
	
	INSERT INTO vr_application_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strApplicationIDs, vr_delimiter) AS ref
	
	SELECT	x.application_id AS application_id,
			x.user_id,
			x.username,
			x.first_name,
			x.last_name,
			(x.row_number + x.rev_row_number - 1) AS total_count
	FROM (
			SELECT	ROW_NUMBER() OVER(PARTITION BY ref.application_id ORDER BY ref.random_id ASC) AS row_number,
					ROW_NUMBER() OVER(PARTITION BY ref.application_id ORDER BY ref.random_id DESC) AS rev_row_number,
					ref.*
			FROM (
					SELECT	app.application_id,
							usr.*,
							gen_random_uuid() AS random_id
					FROM vr_application_ids AS i_ds
						INNER JOIN rv_applications AS app
						ON app.application_id = i_ds.value
						INNER JOIN usr_user_applications AS ua
						ON ua.application_id = app.application_id
						INNER JOIN usr_view_users AS usr
						ON usr.user_id = ua.user_id AND usr.is_approved = TRUE
				) AS ref
		) AS x
	WHERE x.row_number <= vr_count
	ORDER BY x.application_id ASC, x.row_number ASC
END;


DROP PROCEDURE IF EXISTS usr_advanced_user_search;

CREATE PROCEDURE usr_advanced_user_search
	vr_application_id	UUID,
	vr_raw_search_text VARCHAR(1000),
	vr_searchText  VARCHAR(1000),
	vr_strNodeTypeIDs varchar(max),
	vr_strNodeIDs		varchar(max),
	vr_delimiter		char,
	vr_members	 BOOLEAN,
	vr_experts	 BOOLEAN,
	vr_contributors BOOLEAN,
	vr_property_owners BOOLEAN,
	vr_resume		 BOOLEAN,
    vr_lower_boundary	bigint,
    vr_count		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_verify_string(vr_searchText)
	
	DECLARE vr_node_ids GuidTableType
	DECLARE vr_node_type_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_n_count INTEGER = (SELECT COUNT(*) FROM vr_node_ids)
	
	IF vr_n_count = 0 BEGIN
		INSERT INTO vr_node_type_ids (Value)
		SELECT DISTINCT ref.value
		FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	END
	ELSE SET vr_searchText = NULL
	
	DECLARE vr_n_t_count INTEGER = (SELECT COUNT(*) FROM vr_node_type_ids)

	DECLARE vr_nodes TABLE (NodeID UUID, rank float)
	
	DECLARE vr_users TABLE (
		UserID UUID, 
		rank float,
		IsMemberCount INTEGER,
		IsExpertCount INTEGER,
		IsContributorCount INTEGER,
		HasPropertyCount INTEGER,
		resume INTEGER
	)
	
	IF vr_n_count > 0 BEGIN
		INSERT INTO vr_nodes (NodeID, rank)
		SELECT ref.value, 1
		FROM vr_node_ids AS ref
	END
	ELSE BEGIN
		INSERT INTO vr_nodes (NodeID, rank)
		SELECT	nd.node_id,
				ROW_NUMBER() OVER (ORDER BY srch.rank ASC, nd.node_id ASC)
		FROM CONTAINSTABLE(cn_nodes, (name), vr_searchText) AS srch
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = srch.key AND
				nd.deleted = FALSE AND COALESCE(nd.searchable, FALSE) = 1 AND 
				(vr_n_t_count = 0 OR nd.node_type_id IN (SELECT Value FROM vr_node_type_ids))
	END
	
	DECLARE vr_searchedUserIDs TABLE (UserID UUID, rank float)
	DECLARE vr_searchedResume TABLE (UserID UUID, ResumeRank INTEGER)
	
	IF vr_n_count = 0 AND COALESCE(vr_searchText, N'') <> N'' BEGIN
		INSERT INTO vr_searchedUserIDs (UserID, rank)
		SELECT	un.user_id,
				(ROW_NUMBER() OVER (ORDER BY srch.rank ASC, un.user_id ASC)) AS rank
		FROM CONTAINSTABLE(usr_view_users , 
				(FirstName, LastName, UserName), vr_searchText) AS srch
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = srch.key
			
			
		INSERT INTO vr_searchedResume (UserID, ResumeRank)
		SELECT x.user_id, SUM(x.rank)
		FROM (
				SELECT	ea.user_id,
						CAST(1 AS integer) AS rank
				FROM usr_email_addresses AS ea
					INNER JOIN users_normal AS un
					ON un.application_id = vr_application_id AND un.user_id = ea.user_id
				WHERE LOWER(ea.email_address) LIKE (N'%' + LOWER(vr_raw_search_text) + '%') AND ea.deleted = FALSE
					
				UNION ALL
				
				SELECT	pn.user_id,
						CAST(1 AS integer) AS rank
				FROM usr_phone_numbers AS pn
					INNER JOIN users_normal AS un
					ON un.application_id = vr_application_id AND un.user_id = pn.user_id
				WHERE pn.phone_number LIKE (N'%' + LOWER(vr_raw_search_text) + '%') AND pn.deleted = FALSE
		
				UNION ALL
		
				SELECT	e.user_id,
						CAST(1 AS integer) AS rank
				FROM CONTAINSTABLE(usr_educational_experiences, 
						(School, StudyField), vr_searchText) AS srch
					INNER JOIN usr_educational_experiences AS e
					ON e.application_id = vr_application_id AND e.education_id = srch.key
					
				UNION ALL
				
				SELECT	h.user_id,
						CAST(1 AS integer) AS rank
				FROM CONTAINSTABLE(usr_honors_and_awards, 
						(Title, Issuer, Occupation, description), vr_searchText) AS srch
					INNER JOIN usr_honors_and_awards AS h
					ON h.application_id = vr_application_id AND h.id = srch.key
				
				UNION ALL
				
				SELECT	j.user_id,
						CAST(1 AS integer) AS rank
				FROM CONTAINSTABLE(usr_job_experiences, 
						(Title, Employer), vr_searchText) AS srch
					INNER JOIN usr_job_experiences AS j
					ON j.application_id = vr_application_id AND j.job_id = srch.key
					
				UNION ALL
				
				SELECT	u.user_id,
						CAST(1 AS integer) AS rank
				FROM CONTAINSTABLE(usr_language_names, 
						(LanguageName), vr_searchText) AS srch
					INNER JOIN usr_language_names AS l
					ON l.application_id = vr_application_id AND l.language_id = srch.key
					INNER JOIN usr_user_languages AS u
					ON u.application_id = vr_application_id AND u.language_id = l.language_id
			) AS x
		GROUP BY x.user_id
	END

	INSERT INTO vr_users (
		UserID, 
		rank, 
		IsMemberCount, 
		IsExpertCount, 
		IsContributorCount,
		HasPropertyCount,
		resume
	)
	SELECT	users.user_id,
			(SUM(users.rank) + SUM(users.is_member) + 
			SUM(users.is_expert) + SUM(users.is_contributor) + 
			SUM(users.has_property) + SUM(users.resume)) AS rank,
			SUM(users.is_member) AS is_member_count,
			SUM(users.is_expert) AS is_expert_count,
			SUM(users.is_contributor) AS is_contributos_count,
			SUM(users.has_property) AS has_property_count,
			SUM(users.resume) AS resume
	FROM (
			SELECT	u.user_id,
					2 * u.rank AS rank,
					CAST(0 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property,
					CAST(0 AS integer) AS resume
			FROM vr_searchedUserIDs AS u
			
			UNION ALL
			
			SELECT	m.user_id,
					nodes.rank,
					CAST(1 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property,
					CAST(0 AS integer) AS resume
			FROM vr_nodes AS nodes 
				INNER JOIN cn_view_node_members AS m
				ON m.application_id = vr_application_id AND 
					m.node_id = nodes.node_id AND m.is_pending = FALSE
			WHERE vr_members = 1
			
			UNION ALL
			
			SELECT	e.user_id,
					nodes.rank,
					CAST(0 AS integer) AS is_member,
					CAST(1 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property,
					CAST(0 AS integer) AS resume
			FROM vr_nodes AS nodes 
				INNER JOIN cn_view_experts AS e
				ON e.application_id = vr_application_id AND e.node_id = nodes.node_id
			WHERE vr_experts = 1
				
			UNION ALL
			
			SELECT	c.user_id,
					nodes.rank,
					CAST(0 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(1 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property,
					CAST(0 AS integer) AS resume
			FROM vr_nodes AS nodes 
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND 
					c.node_id = nodes.node_id AND c.deleted = FALSE
			WHERE vr_contributors = 1
				
			UNION ALL
			
			SELECT	c.user_id,
					nodes.seq_no AS rank,
					CAST(0 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(1 AS integer) AS has_property,
					CAST(0 AS integer) AS resume
			FROM (
					SELECT n.node_id, MAX(n.rank) AS seq_no
					FROM (
							SELECT i.related_node_id AS node_id, nodes.rank
							FROM vr_nodes AS nodes 
								INNER JOIN cn_view_in_related_nodes AS i
								ON i.application_id = vr_application_id AND 
									i.node_id = nodes.node_id
								
							UNION ALL
							
							SELECT o.related_node_id AS node_id, nodes.rank
							FROM vr_nodes AS nodes 
								INNER JOIN cn_view_out_related_nodes AS o
								ON o.application_id = vr_application_id AND 
									o.node_id = nodes.node_id
						) AS n
					GROUP BY n.node_id
				) AS nodes
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND 
					c.node_id = nodes.node_id AND c.deleted = FALSE
			WHERE vr_property_owners = 1
			
			UNION ALL
			
			SELECT	r.user_id,
					1 AS rank,
					CAST(0 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property,
					r.resume_rank AS resume
			FROM vr_searchedResume AS r
			WHERE vr_resume = 1
		) AS users
	GROUP BY users.user_id

	SELECT TOP(COALESCE(vr_count, 20)) 
		x.user_id, 
		(x.row_number + x.rev_row_number - 1) AS total_count,
		x.rank,
		x.is_member_count,
		x.is_expert_count,
		x.is_contributor_count,
		x.has_property_count,
		x.resume
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY u.rank DESC, u.user_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY u.rank ASC, u.user_id DESC) AS rev_row_number,
					u.*
			FROM vr_users AS u
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND 
					un.user_id = u.user_id AND un.is_approved = TRUE
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
END;


DROP PROCEDURE IF EXISTS usr_advanced_user_search_meta;

CREATE PROCEDURE usr_advanced_user_search_meta
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_searchText  VARCHAR(1000),
	vr_strNodeTypeIDs varchar(max),
	vr_strNodeIDs		varchar(max),
	vr_delimiter		char,
	vr_members	 BOOLEAN,
	vr_experts	 BOOLEAN,
	vr_contributors BOOLEAN,
	vr_property_owners BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_verify_string(vr_searchText)
	
	DECLARE vr_node_ids GuidTableType
	DECLARE vr_node_type_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_n_count INTEGER = (SELECT COUNT(*) FROM vr_node_ids)
	
	IF vr_n_count = 0 BEGIN
		INSERT INTO vr_node_type_ids (Value)
		SELECT DISTINCT ref.value
		FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	END
	ELSE SET vr_searchText = NULL
	
	DECLARE vr_n_t_count INTEGER = (SELECT COUNT(*) FROM vr_node_type_ids)

	DECLARE vr_nodes TABLE (NodeID UUID, rank float)

	IF vr_n_count > 0 BEGIN
		INSERT INTO vr_nodes (NodeID, rank)
		SELECT ref.value, 1
		FROM vr_node_ids AS ref
	END
	ELSE BEGIN
		INSERT INTO vr_nodes (NodeID, rank)
		SELECT	nd.node_id,
				ROW_NUMBER() OVER (ORDER BY srch.rank ASC, nd.node_id ASC)
		FROM CONTAINSTABLE(cn_nodes, (name), vr_searchText) AS srch
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = srch.key AND
				nd.deleted = FALSE AND COALESCE(nd.searchable, FALSE) = 1 AND 
				(vr_n_t_count = 0 OR nd.node_type_id IN (SELECT Value FROM vr_node_type_ids))
	END

	SELECT	nodes.node_id,
			SUM(nodes.rank) AS rank,
			CAST(MAX(nodes.is_member) AS boolean) AS is_member,
			CAST(MAX(nodes.is_expert) AS boolean) AS is_expert,
			CAST(MAX(nodes.is_contributor) AS boolean) AS is_contributor,
			CAST(MAX(nodes.has_property) AS boolean) AS has_property
	FROM (	
			SELECT	m.node_id,
					nodes.rank,
					CAST(1 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property
			FROM vr_nodes AS nodes 
				INNER JOIN cn_view_node_members AS m
				ON m.application_id = vr_application_id AND 
					m.node_id = nodes.node_id AND m.is_pending = FALSE
			WHERE vr_members = 1 AND m.user_id = vr_user_id
			
			UNION ALL
			
			SELECT	e.node_id,
					nodes.rank,
					CAST(0 AS integer) AS is_member,
					CAST(1 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property
			FROM vr_nodes AS nodes 
				INNER JOIN cn_view_experts AS e
				ON e.application_id = vr_application_id AND e.node_id = nodes.node_id
			WHERE vr_experts = 1 AND e.user_id = vr_user_id
				
			UNION ALL
			
			SELECT	c.node_id,
					nodes.rank,
					CAST(0 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(1 AS integer) AS is_contributor,
					CAST(0 AS integer) AS has_property
			FROM vr_nodes AS nodes 
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND 
					c.node_id = nodes.node_id AND c.deleted = FALSE
			WHERE vr_contributors = 1 AND c.user_id = vr_user_id
				
			UNION ALL
			
			SELECT	nodes.base_node_id AS node_id,
					MAX(nodes.seq_no) AS rank,
					CAST(0 AS integer) AS is_member,
					CAST(0 AS integer) AS is_expert,
					CAST(0 AS integer) AS is_contributor,
					CAST(1 AS integer) AS has_property
			FROM (
					SELECT	n.node_id, 
							CAST(MAX(CAST(n.base_node_id AS varchar(50))) AS uuid) AS base_node_id, 
							MAX(n.rank) AS seq_no
					FROM (
							SELECT	i.node_id AS base_node_id, 
									i.related_node_id AS node_id, 
									nodes.rank
							FROM vr_nodes AS nodes 
								INNER JOIN cn_view_in_related_nodes AS i
								ON i.application_id = vr_application_id AND 
									i.node_id = nodes.node_id
								
							UNION ALL
							
							SELECT	o.node_id AS base_node_id,
									o.related_node_id AS node_id, 
									nodes.rank
							FROM vr_nodes AS nodes 
								INNER JOIN cn_view_out_related_nodes AS o
								ON o.application_id = vr_application_id AND 
									o.node_id = nodes.node_id
						) AS n
					GROUP BY n.node_id
				) AS nodes
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND 
					c.node_id = nodes.node_id AND c.deleted = FALSE
			WHERE vr_property_owners = 1 AND c.user_id = vr_user_id
			GROUP BY nodes.base_node_id
		) AS nodes
	GROUP BY nodes.node_id
END;


DROP PROCEDURE IF EXISTS usr_p_create_system_user;

CREATE PROCEDURE usr_p_create_system_user
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM users_normal
		WHERE (vr_application_id IS NULL OR ApplicationId = vr_application_id) AND LoweredUserName = N'system'
	) BEGIN
		INSERT INTO rv_users (user_id, username, 
			lowered_username, mobile_alias, is_anonymous, last_activity_date) 
		VALUES (vr_user_id, N'system', N'system', NULL, 0, CAST(0x0000A1A900C898BC AS timestamp))
		
		INSERT INTO usr_profile ( 
			user_id, 
			first_name,
			lastname, 
			birthdate
		) 
		VALUES (vr_user_id, N'رای', N'ون', NULL)
			
		INSERT INTO rv_membership (user_id, password, 
			password_format, password_salt, mobile_pin, email, lowered_email, 
			password_question, password_answer, is_approved, is_locked_out, create_date, 
			last_login_date, last_password_changed_date, last_lockout_date, 
			failed_password_attempt_count, failed_password_attempt_window_start, 
			failed_password_answer_attempt_count, failed_password_answer_attempt_window_start, 
			comment) 
		VALUES (vr_user_id, N'saS+wizpq8cetvwnCAdCAHek3Ls=', 1, N'0QnG9cGvuzB99qo+ycdaow==', NULL, NULL, NULL, NULL, 
			NULL, 1, 0, CAST(0x0000A1A900C898BC AS timestamp), CAST(0x0000A1A900C898BC AS timestamp), 
			CAST(0x0000A1A900C898BC AS timestamp), CAST(0xFFFF2FB300000000 AS timestamp), 0, 
			CAST(0xFFFF2FB300000000 AS timestamp), 0, CAST(0xFFFF2FB300000000 AS timestamp), NULL)
			
		IF vr_application_id IS NOT NULL BEGIN
			INSERT INTO usr_user_applications (ApplicationID, UserID)
			VALUES (vr_application_id, vr_user_id)
		END
	END
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS usr_get_system_user;

CREATE PROCEDURE usr_get_system_user
	vr_application_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids KeyLessGuidTableType
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM users_normal
		WHERE (vr_application_id IS NULL OR ApplicationId = vr_application_id) AND LoweredUserName = N'system'
	) BEGIN
		DECLARE vr_user_id UUID = gen_random_uuid()
		DECLARE vr__result INTEGER
		
		INSERT INTO vr_user_ids (Value) 
		VALUES (vr_user_id)
		
		EXEC usr_p_create_system_user vr_application_id, vr_user_id, vr__result output
	END
	ELSE BEGIN
		IF vr_application_id IS NULL BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT UserId
			FROM usr_view_users
			WHERE LoweredUserName = N'system'
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT UserId
			FROM users_normal
			WHERE ApplicationID = vr_application_id AND LoweredUserName = N'system'
		END
	END
	
	EXEC usr_p_get_users_by_ids vr_application_id, vr_user_ids
END;


DROP PROCEDURE IF EXISTS usr_create_admin_user;

CREATE PROCEDURE usr_create_admin_user
	vr_application_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM users_normal
		WHERE ApplicationId = vr_application_id AND LoweredUserName = N'admin'
	) BEGIN
		DECLARE vr_adminRoleID UUID = (
			SELECT TOP(1) RoleID
			FROM rv_roles
			WHERE ApplicationID = vr_application_id AND LoweredRoleName = N'admins'
		)
	
		IF vr_adminRoleID IS NULL BEGIN
			SET vr_adminRoleID = gen_random_uuid()
		
			INSERT INTO rv_roles (
				ApplicationID,
				RoleID,
				RoleName,
				LoweredRoleName
			)
			VALUES (
				vr_application_id,
				vr_adminRoleID,
				N'Admins',
				N'admins'
			)
		END
	
		DECLARE vr_user_id UUID = gen_random_uuid()
	
		INSERT INTO rv_users (user_id, username, 
			lowered_username, mobile_alias, is_anonymous, last_activity_date) 
		VALUES (vr_user_id, N'admin', N'admin', NULL, 0, CAST(0x0000A1A900C898BC AS timestamp))
			
		INSERT INTO rv_users_in_roles (UserID, RoleID)
		VALUES (vr_user_id, vr_adminRoleID)
		
		INSERT INTO usr_profile (
			user_id, 
			first_name,
			lastname, 
			birthdate
		) 
		VALUES (vr_user_id, N'مدیر', N'سیستم', NULL)
			
		INSERT INTO rv_membership (user_id, password, 
			password_format, password_salt, mobile_pin, email, lowered_email, 
			password_question, password_answer, is_approved, is_locked_out, create_date, 
			last_login_date, last_password_changed_date, last_lockout_date, 
			failed_password_attempt_count, failed_password_attempt_window_start, 
			failed_password_answer_attempt_count, failed_password_answer_attempt_window_start, 
			comment) 
		VALUES (vr_user_id, N'hzpljiwy35CCLSmxIuTk49mhDI4=', 1, N'6rG7hIBmkJ6cfestS4Ycow==', NULL, NULL, NULL, NULL, 
			NULL, 1, 0, CAST(0x0000A1A900C898BC AS timestamp), CAST(0x0000A1A900C898BC AS timestamp), 
			CAST(0x0000A1A900C898BC AS timestamp), CAST(0xFFFF2FB300000000 AS timestamp), 0, 
			CAST(0xFFFF2FB300000000 AS timestamp), 0, CAST(0xFFFF2FB300000000 AS timestamp), NULL)
			
		INSERT INTO usr_user_applications (ApplicationID, UserID)
		VALUES (vr_application_id, vr_user_id)
	END
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS usr_get_not_existing_users;

CREATE PROCEDURE usr_get_not_existing_users
	vr_application_id	UUID,
    vr_usernamesTemp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_usernames StringTableType
	INSERT INTO vr_usernames SELECT * FROM vr_usernamesTemp
	
	SELECT DISTINCT ref.value AS value
	FROM vr_usernames AS ref
	WHERE NOT EXISTS(
			SELECT TOP(1) * 
			FROM users_normal
			WHERE ApplicationID = vr_application_id AND 
				UserName = ref.value OR LoweredUserName = LOWER(ref.value)
		)
END;


DROP PROCEDURE IF EXISTS usr_register_item_visit;

CREATE PROCEDURE usr_register_item_visit
	vr_application_id	UUID,
    vr_itemID			UUID,
    vr_user_id			UUID,
    vr_visit_date	 TIMESTAMP,
    vr_itemType		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO usr_item_visits(
		ApplicationID,
		ItemID,
		VisitDate,
		UserID,
		ItemType,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_itemID,
		vr_visit_date,
		vr_user_id,
		vr_itemType,
		gen_random_uuid()
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_items_visits_count;

CREATE PROCEDURE usr_get_items_visits_count
	vr_application_id	UUID,
    vr_str_itemIDs		UUID,
    vr_delimiter		char,
    vr_lower_date_limit TIMESTAMP,
    vr_upper_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_itemIDs GuidTableType
	INSERT INTO vr_itemIDs
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_str_itemIDs, vr_delimiter) AS ref
	
	SELECT external_ids.value AS item_id,
		   (
				SELECT COUNT(*) 
				FROM usr_item_visits
				WHERE ApplicationID = vr_application_id AND ItemID = external_ids.value AND
					(vr_lower_date_limit IS NULL OR VisitDate >= vr_lower_date_limit) AND
					(vr_upper_date_limit IS NULL OR VisitDate <= vr_upper_date_limit)
			) AS visits_count
	FROM vr_itemIDs AS external_ids
END;


DROP PROCEDURE IF EXISTS usr_send_friendship_request;

CREATE PROCEDURE usr_send_friendship_request
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_receiver_user_id	UUID,
    vr_request_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM usr_friends
		WHERE ApplicationID = vr_application_id AND 
			((SenderUserID = vr_user_id AND ReceiverUserID = vr_receiver_user_id) OR
			(SenderUserID = vr_receiver_user_id AND ReceiverUserID = vr_user_id))
	) BEGIN
		INSERT INTO usr_friends(
			ApplicationID,
			SenderUserID,
			ReceiverUserID,
			RequestDate,
			AreFriends,
			Deleted,
			UniqueID
		)
		VALUES(
			vr_application_id,
			vr_user_id,
			vr_receiver_user_id,
			vr_request_date,
			0,
			0,
			gen_random_uuid()
		)
	END
	ELSE BEGIN
		UPDATE usr_friends
			SET SenderUserID = vr_user_id,
				ReceiverUserID = vr_receiver_user_id,
				RequestDate = vr_request_date,
				AcceptionDate = NULL,
			 are_friends = FALSE,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND
			(SenderUserID = vr_user_id AND ReceiverUserID = vr_receiver_user_id) OR
			(SenderUserID = vr_receiver_user_id AND ReceiverUserID = vr_user_id)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_accept_friendship;

CREATE PROCEDURE usr_accept_friendship
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_senderUserID	UUID,
    vr_acceptionDate TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_friends
		SET are_friends = TRUE,
			AcceptionDate = vr_acceptionDate
	WHERE ApplicationID = vr_application_id AND 
		SenderUserID = vr_senderUserID AND ReceiverUserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_reject_friendship;

CREATE PROCEDURE usr_reject_friendship
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_friend_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_friends
		SET are_friends = FALSE,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND 
		(SenderUserID = vr_user_id AND ReceiverUserID = vr_friend_user_id) OR
		(SenderUserID = vr_friend_user_id AND ReceiverUserID = vr_user_id)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_friendship_status;

CREATE PROCEDURE usr_get_friendship_status
	vr_application_id		UUID,
    vr_user_id				UUID,
    vr_strOtherUserIDs	varchar(max),
    vr_delimiter			char,
    vr_mutuals_count	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_other_user_ids GuidTableType
	INSERT INTO vr_other_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strOtherUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_retTbl TABLE (
		UserID				UUID,
		IsFriend		 BOOLEAN,
		IsSender		 BOOLEAN,
		MutualFriendsCount INTEGER
	)
	
	INSERT INTO vr_retTbl (UserID, IsFriend, IsSender)
	SELECT	o.value AS user_id,
			COALESCE(f.are_friends, FALSE) AS is_friend,
			COALESCE(f.is_sender, FALSE) AS is_sender
	FROM vr_other_user_ids AS o
		INNER JOIN usr_view_friends AS f
		ON f.user_id = vr_user_id AND f.friend_id = o.value
	WHERE f.application_id = vr_application_id
		
	IF vr_mutuals_count = 1 BEGIN
		UPDATE Ref
			SET MutualFriendsCount = m.mutual_friends_count
		FROM vr_retTbl AS ref
			LEFT JOIN usr_fn_get_mutual_friends_count(vr_application_id, vr_user_id, vr_other_user_ids) AS m
			ON ref.user_id = m.user_id
	END
	
	SELECT *
	FROM vr_retTbl
END;


DROP PROCEDURE IF EXISTS usr_p_update_friend_suggestions;

CREATE PROCEDURE usr_p_update_friend_suggestions
	vr_application_id	UUID,
    vr_user_idsTemp	GuidTableType readonly,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	INSERT INTO vr_user_ids SELECT * FROM vr_user_idsTemp
	
	DECLARE vr_suggestions TABLE (
		UserID UUID, 
		OtherUserID UUID, 
		Score FLOAT
	)
	
	
	-- Fetch All of the Selected Data and Calculate Score for Each Suggestion
	
	INSERT INTO vr_suggestions (UserID, OtherUserID, Score)
	SELECT	d.user_id, 
			d.other_user_id,
			(
				(20 * MAX(d.groups_count)) + 
				(50 * MAX(d.has_invitation)) + 
				(10 * MAX(d.mutuals_count))
			) AS score
	FROM (
			-- Select FriendsOfFriends With Mutual Friends Count
			
			SELECT	f.user_id, 
					f2.friend_id AS other_user_id, 
					COUNT(f.friend_id) AS mutuals_count,
					CAST(0 AS integer) AS has_invitation, 
					CAST(0 AS integer) AS groups_count
			FROM vr_user_ids AS ref
				INNER JOIN usr_view_friends AS f
				ON f.user_id = ref.value
				INNER JOIN usr_view_friends AS f2
				ON f2.application_id = vr_application_id AND 
					f2.user_id = f.friend_id AND f2.friend_id <> f.user_id
				LEFT JOIN usr_view_friends AS l1
				ON l1.application_id = vr_application_id AND 
					l1.user_id = f.user_id AND l1.friend_id = f2.friend_id
			WHERE f.application_id = vr_application_id AND 
				f.are_friends = TRUE AND f2.are_friends = TRUE AND l1.user_id IS NULL
			GROUP BY f.user_id, f2.friend_id
			
			-- end of Select FriendsOfFriends With Mutual Friends Count
			
			UNION ALL
			
			-- Calculate Mutual Friends Count for 'Invitations' and 'Groupmates'

			SELECT	y.user_id, 
					y.other_user_id, 
					SUM(
						CASE 
							WHEN f.user_id IS NOT NULL AND f2.user_id IS NOT NULL AND
								f.are_friends = TRUE AND f2.are_friends = TRUE AND 
								f2.friend_id <> y.user_id AND f.friend_id <> y.other_user_id
							THEN 1
							ELSE 0
						END
					) AS mutuals_count,
					MAX(y.has_invitation) AS has_invitation, 
					MAX(y.groups_count) AS groups_count
			FROM (
					-- Fetch 'Invitations' and 'Groupmates' and Remove Pairs Who Are Already Friends
					
					SELECT	ref.user_id, 
							ref.other_user_id, 
							SUM(ref.has_invitation) AS has_invitation,
							SUM(ref.groups_count) AS groups_count
					FROM (
							-- Suggest Friends Based on Invitations
							
							SELECT DISTINCT
									ref.value AS user_id,
									(
										CASE 
											WHEN i.sender_user_id = ref.value THEN i.created_user_id 
											ELSE i.sender_user_id END
									) AS other_user_id,
									CAST(1 AS integer) AS has_invitation,
									0 AS groups_count
							FROM vr_user_ids AS ref
								INNER JOIN usr_invitations AS i
								ON i.application_id = vr_application_id AND
									i.sender_user_id = ref.value OR i.created_user_id = ref.value
								INNER JOIN users_normal AS un
								ON un.application_id = vr_application_id AND 
									un.user_id = i.created_user_id
								
							-- end of Suggest Friends Based on Invitations
								
							UNION ALL
							
							-- Suggest Friends Based on Being Groupmate
							
							SELECT	nm.user_id, 
									nm2.user_id AS other_user_id, 
									0 AS has_invitation,
									COUNT(nm.node_id) AS groups_count
							FROM vr_user_ids AS ref
								INNER JOIN cn_view_node_members AS nm
								ON nm.application_id = vr_application_id AND 
									nm.user_id = ref.value AND nm.is_pending = FALSE
								INNER JOIN cn_view_node_members AS nm2
								ON nm2.application_id = vr_application_id AND 
									nm2.node_id = nm.node_id AND nm2.user_id <> nm.user_id AND
									nm2.is_pending = FALSE
							GROUP BY nm.user_id, nm2.user_id
							
							-- end of Suggest Friends Based on Being Groupmate
						) AS ref
						LEFT JOIN usr_view_friends AS f
						ON f.application_id = vr_application_id AND 
							f.user_id = ref.user_id AND f.friend_id = ref.other_user_id
					WHERE f.user_id IS NULL
					GROUP BY ref.user_id, ref.other_user_id
					
					-- end of Fetch 'Invitations' and 'Groupmates' and Remove Pairs Who Are Already Friends
				) AS y
				LEFT JOIN usr_view_friends AS f
				ON f.application_id = vr_application_id AND f.user_id = y.user_id
				LEFT JOIN usr_view_friends AS f2
				ON f2.application_id = vr_application_id AND 
					f2.user_id = y.other_user_id AND f2.friend_id = f.friend_id
			GROUP BY y.user_id, y.other_user_id
			
			-- end of Calculate Mutual Friends Count for 'Invitations' and 'Groupmates'
		) AS d
	GROUP BY d.user_id, d.other_user_id
	
	-- end of Fetch All of the Selected Data and Calculate Score for Each Suggestion
	
	
	-- Remove Suggestions Collected for Target Users
	
	DELETE FS
	FROM vr_user_ids AS ref
		INNER JOIN usr_friend_suggestions AS fs
		ON fs.application_id = vr_application_id AND fs.user_id = ref.value
		
	-- end of Remove Suggestions Collected for Target Users	
	
	
	-- Insert Collected Suggestions Into USR_FriendSuggestions Table

	INSERT INTO usr_friend_suggestions (
		ApplicationID,
		UserID, 
		SuggestedUserID, 
		Score
	)
	SELECT DISTINCT
		vr_application_id,
		fs.user_id,
		fs.other_user_id,
		fs.score
	FROM vr_suggestions AS fs
	WHERE fs.user_id <> fs.other_user_id
	
	-- end of Insert Collected Suggestions Into USR_FriendSuggestions Table
	

	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS usr_update_friend_suggestions;

CREATE PROCEDURE usr_update_friend_suggestions
	vr_application_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs TABLE (ID bigint IDENTITY(1, 1) primary key clustered, UserID UUID)
	
	IF vr_user_id IS NULL BEGIN
		INSERT INTO vr_iDs (UserID)
		SELECT DISTINCT f.user_id
		FROM usr_view_friends AS f
		WHERE f.application_id = vr_application_id
	END
	ELSE INSERT INTO vr_iDs (UserID) VALUES(vr_user_id)
	
	DECLARE vr__result INTEGER = 0
	
	DECLARE vr_user_ids GuidTableType
	DECLARE vr_count bigint = (SELECT MAX(ID) FROM vr_iDs)
	DECLARE vr_batchSize bigint = 50, vr_lower bigint = 0
	
	WHILE vr_count > 0 BEGIN
		DELETE vr_user_ids
		
		INSERT INTO vr_user_ids(Value)
		SELECT ref.user_id
		FROM vr_iDs AS ref
		WHERE ref.id > vr_lower AND ref.id <= vr_lower + vr_batchSize
	
		EXEC usr_p_update_friend_suggestions vr_application_id, vr_user_ids, vr__result output
		
		SET vr_lower = vr_lower + vr_batchSize
		SET vr_count = vr_count - vr_batchSize
	END
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS usr_get_friend_suggestions;

CREATE PROCEDURE usr_get_friend_suggestions
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_count		 INTEGER,
    vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_retTbl Table (UserID UUID, FirstName VARCHAR(500), 
		LastName VARCHAR(500), MutualFriendsCount INTEGER, order bigint, TotalCount bigint)
	
	INSERT INTO vr_retTbl (UserID, FirstName, LastName, order, TotalCount)
	SELECT TOP(COALESCE(vr_count, 100000))
		f.suggested_user_id,
		f.first_name,
		f.last_name,
		f.row_number AS order,
		(f.row_number + f.rev_row_number - 1) AS total_count
	FROM (
			SELECT
				s.suggested_user_id,
				un.first_name,
				un.last_name,
				ROW_NUMBER() OVER (ORDER BY s.score DESC, s.suggested_user_id DESC) AS row_number,
				ROW_NUMBER() OVER (ORDER BY s.score ASC, s.suggested_user_id ASC) AS rev_row_number
			FROM usr_friend_suggestions AS s
				LEFT JOIN usr_view_friends AS f
				ON f.application_id = vr_application_id AND 
					f.user_id = s.user_id AND f.friend_id = s.suggested_user_id
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = s.suggested_user_id
			WHERE s.application_id = vr_application_id AND s.user_id = vr_user_id AND un.is_approved = TRUE AND f.user_id IS NULL
		) AS f
	WHERE f.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY f.row_number ASC
	
	DECLARE vr_other_user_ids GuidTableType
	INSERT INTO vr_other_user_ids
	SELECT ref.user_id
	FROM vr_retTbl AS ref
	
	UPDATE Ref
		SET MutualFriendsCount = o.mutual_friends_count
	FROM vr_retTbl AS ref
		INNER JOIN usr_fn_get_mutual_friends_count(vr_application_id, vr_user_id, vr_other_user_ids) AS o
		ON ref.user_id = o.user_id
		
	SELECT *
	FROM vr_retTbl AS ref
	ORDER BY ref.order DESC
END;


DROP PROCEDURE IF EXISTS usr_get_friend_ids;

CREATE PROCEDURE usr_get_friend_ids
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_areFriends	 BOOLEAN,
    vr_sent		 BOOLEAN,
    vr_received	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ref.user_id AS id
	FROM usr_fn_get_friend_ids(vr_application_id, vr_user_id, vr_areFriends, vr_sent, vr_received) AS ref
END;


DROP PROCEDURE IF EXISTS usr_get_friends;

CREATE PROCEDURE usr_get_friends
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_strFriendIDs	varchar(max),
    vr_delimiter		char,
    vr_mutuals_count BOOLEAN,
    vr_areFriends	 BOOLEAN,
    vr_isSender	 BOOLEAN,
    vr_searchText	 VARCHAR(1000),
    vr_count		 INTEGER,
    vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_searchText = N'' SET vr_searchText = NULL
	
	DECLARE vr_friend_ids GuidTableType
	INSERT INTO vr_friend_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strFriendIDs, vr_delimiter) AS ref
	
	DECLARE vr_f_ids_count INTEGER = (SELECT COUNT(*) FROM vr_friend_ids)
	
	IF vr_f_ids_count > 0 SET vr_count = 1000000
	
	DECLARE vr_x Table (FriendID UUID primary key clustered,
		UserName VARCHAR(1000), FirstName VARCHAR(1000), LastName VARCHAR(1000),
		RequestDate TIMESTAMP, AcceptionDate TIMESTAMP, AreFriends BOOLEAN,
		IsSender BOOLEAN, RowNumber bigint, RevRowNumber bigint)
	
	IF vr_searchText IS NULL BEGIN
		INSERT INTO vr_x (
			FriendID, UserName, FirstName, LastName, RequestDate, 
			AcceptionDate, AreFriends, IsSender, RowNumber, RevRowNumber
		)
		SELECT f.friend_id, f.username, f.first_name, f.last_name, 
			f.request_date, f.acception_date, f.are_friends, f.is_sender,
			ROW_NUMBER() OVER (ORDER BY f.last_activity_date DESC, f.friend_id DESC) AS row_number,
			ROW_NUMBER() OVER (ORDER BY f.last_activity_date ASC, f.friend_id ASC) AS rev_row_number
		FROM (
			SELECT un.user_id AS friend_id,
				   un.username AS username,
				   un.first_name AS first_name,
				   un.last_name AS last_name,
				   fr.request_date AS request_date,
				   fr.acception_date AS acception_date,
				   fr.are_friends AS are_friends,
				   fr.is_sender AS is_sender,
				   un.last_activity_date
			FROM usr_view_friends AS fr
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = fr.friend_id
			WHERE fr.application_id = vr_application_id AND 
				vr_searchText IS NULL AND fr.user_id = vr_user_id AND
				(vr_isSender IS NULL OR fr.is_sender = vr_isSender) AND
				(vr_f_ids_count = 0 OR fr.friend_id IN (SELECT * FROM vr_friend_ids)) AND
				(vr_areFriends IS NULL OR fr.are_friends = vr_areFriends)
		) AS f	
	END
	ELSE BEGIN
		INSERT INTO vr_x (
			FriendID, UserName, FirstName, LastName, RequestDate, 
			AcceptionDate, AreFriends, IsSender, RowNumber, RevRowNumber
		)
		SELECT f.friend_id, f.username, f.first_name, f.last_name, 
			f.request_date, f.acception_date, f.are_friends, f.is_sender,
			ROW_NUMBER() OVER (ORDER BY f.rank DESC, f.last_activity_date DESC, f.friend_id DESC) AS row_number,
			ROW_NUMBER() OVER (ORDER BY f.rank ASC, f.last_activity_date ASC, f.friend_id ASC) AS rev_row_number
		FROM (
			SELECT un.user_id AS friend_id,
				   un.username AS username,
				   un.first_name AS first_name,
				   un.last_name AS last_name,
				   fr.request_date AS request_date,
				   fr.acception_date AS acception_date,
				   fr.are_friends AS are_friends,
				   fr.is_sender AS is_sender,
				   un.last_activity_date,
				   srch.rank AS rank
			FROM CONTAINSTABLE(usr_view_users, 
					(FirstName, LastName, UserName), vr_searchText) AS srch
				INNER JOIN usr_view_friends AS fr
				ON fr.friend_id = srch.key
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = fr.friend_id
			WHERE fr.application_id = vr_application_id AND 
				vr_searchText IS NOT NULL AND fr.user_id = vr_user_id AND
				(vr_isSender IS NULL OR fr.is_sender = vr_isSender) AND
				(vr_f_ids_count = 0 OR fr.friend_id IN (SELECT * FROM vr_friend_ids)) AND
				(vr_areFriends IS NULL OR fr.are_friends = vr_areFriends)
		) AS f
	END

	SELECT TOP(COALESCE(vr_count, 1000000)) *
	FROM (
			SELECT
				my_friends.friend_id,
				MAX(my_friends.username) AS username,
				MAX(my_friends.first_name) AS first_name,
				MAX(my_friends.last_name) AS last_name,
				MAX(my_friends.request_date) AS request_date,
				MAX(my_friends.acception_date) AS acception_date,
				CAST(MAX(CAST(my_friends.are_friends AS integer)) AS boolean) AS are_friends,
				CAST(MAX(CAST(my_friends.is_sender AS integer)) AS boolean) AS is_sender,
				COUNT(friends_of_friends.friend_of_friend) AS mutual_friends_count,
				MAX(my_friends.row_number) AS order,
				(MAX(my_friends.row_number) + MAX(my_friends.rev_row_number) - 1) AS total_count
			FROM vr_x AS my_friends
				LEFT JOIN (
					SELECT x.friend_id AS friend, 
						CASE 
							WHEN uc.sender_user_id = x.friend_id THEN uc.receiver_user_id
							ELSE uc.sender_user_id
						END AS friend_of_friend
					FROM vr_x AS x
						INNER JOIN usr_friends AS uc
						ON uc.application_id = vr_application_id AND 
							uc.are_friends = TRUE AND uc.deleted = FALSE AND (
								uc.receiver_user_id = x.friend_id OR uc.sender_user_id = x.friend_id
							)
				) FriendsOfFriends
				ON vr_mutuals_count = 1 AND my_friends.friend_id = friends_of_friends.friend_of_friend
			GROUP BY my_friends.friend_id
		) AS f
	WHERE f.order >= COALESCE(vr_lower_boundary, 0)
	ORDER BY f.order ASC
END;


DROP PROCEDURE IF EXISTS usr_get_friends_count;

CREATE PROCEDURE usr_get_friends_count
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_areFriends	 BOOLEAN,
    vr_sent		 BOOLEAN,
    vr_received	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(FriendID)
	FROM usr_view_friends
	WHERE ApplicationID = vr_application_id AND 
		UserID = vr_user_id AND (vr_areFriends IS NULL OR AreFriends = vr_areFriends) AND
		((vr_sent = 1 AND is_sender = TRUE) OR (vr_received = 1 AND is_sender = FALSE))
END;


DROP PROCEDURE IF EXISTS usr_p_save_email_contacts;

CREATE PROCEDURE usr_p_save_email_contacts	
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_emailsTemp		StringTableType readonly,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_emails StringTableType
	INSERT INTO vr_emails SELECT * FROM vr_emailsTemp
	
	UPDATE C
		SET deleted = FALSE
	FROM vr_emails AS e
		INNER JOIN usr_email_contacts AS c
		ON c.email = LOWER(e.value)
	WHERE c.user_id = vr_user_id
	
	SET vr__result = @vr_rowcount
	
	INSERT INTO usr_email_contacts(
		UserID,
		Email, 
		CreationDate, 
		Deleted, 
		UniqueID
	)
	SELECT ref.user_id, ref.email, ref.now, ref.deleted, gen_random_uuid()
	FROM (
			SELECT DISTINCT vr_user_id AS user_id, LOWER(e.value) AS email, 
				vr_now AS now, 0 AS deleted
			FROM vr_emails AS e
				LEFT JOIN usr_email_contacts AS c
				ON c.user_id = vr_user_id AND c.email = LOWER(e.value)
			WHERE c.user_id IS NULL
		) AS ref
	
	SET vr__result = vr__result + @vr_rowcount
	
	IF vr__result <= 0 AND (SELECT TOP (1) * FROM vr_emails) IS NULL SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS usr_get_email_contacts_status;

CREATE PROCEDURE usr_get_email_contacts_status
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_emailsTemp		StringTableType readonly,
    vr_saveEmails	 BOOLEAN,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_emails StringTableType
	INSERT INTO vr_emails SELECT * FROM vr_emailsTemp
	
	IF vr_saveEmails = 1 BEGIN
		DECLARE vr__result INTEGER = 0
	
		EXEC usr_p_save_email_contacts vr_application_id, 
			vr_user_id, vr_emails, vr_now, vr__result output
	END
	
	SELECT	emails.email,
			emails.user_id,
			CAST((CASE WHEN fr.is_sender IS NULL THEN 0 ELSE 1 END) AS boolean) AS friend_request_received
	FROM (
			SELECT DISTINCT
					ea.user_id,
					LOWER(e.value) AS email
			FROM vr_emails AS e
				LEFT JOIN usr_email_addresses AS ea
				ON ea.deleted = FALSE AND LOWER(ea.email_address) = LOWER(e.value)
			WHERE ea.user_id IS NULL OR ea.user_id <> vr_user_id
		) AS emails
		LEFT JOIN usr_view_friends AS fr
		ON fr.application_id = vr_application_id AND 
			fr.user_id = vr_user_id AND fr.friend_id = emails.user_id
	WHERE fr.are_friends IS NULL OR (fr.are_friends = FALSE AND fr.is_sender = FALSE)
END;


DROP PROCEDURE IF EXISTS usr_set_theme;

CREATE PROCEDURE usr_set_theme
	vr_user_id			UUID,
    vr_theme			varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET Theme = vr_theme
	WHERE UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_theme;

CREATE PROCEDURE usr_get_theme
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Theme
	FROM usr_profile
	WHERE UserID = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_set_verification_code_media;

CREATE PROCEDURE usr_set_verification_code_media
	vr_user_id		UUID,
	vr_media		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET TwoStepAuthentication = vr_media
	WHERE UserID = vr_user_id

	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_approved_user_ids;

CREATE PROCEDURE usr_get_approved_user_ids
	vr_application_id	UUID,
    vr_strUserIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	SELECT un.user_id AS id
	FROM vr_user_ids AS u
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = u.value
	WHERE un.is_approved = TRUE
END;


DROP PROCEDURE IF EXISTS usr_set_last_activity_date;

CREATE PROCEDURE usr_set_last_activity_date
    vr_user_id			UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE rv_users
		SET LastActivityDate = vr_now
	WHERE UserId = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_add_or_modify_remote_server;

CREATE PROCEDURE usr_add_or_modify_remote_server
	vr_application_id	UUID,
	vr_serverID		UUID,
	vr_user_id			UUID,
	vr_name		 VARCHAR(255),
	vr_url		 VARCHAR(100),
	vr_username	 VARCHAR(100),
	vr_password		varbinary(100),
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) ServerID
		FROM usr_remote_servers
		WHERE ApplicationID = vr_application_id AND ServerID = vr_serverID AND UserID = vr_user_id
	) BEGIN
		UPDATE usr_remote_servers
			Set Name = vr_name,
				URL = vr_url,
				UserName = vr_username,
				password = vr_password,
				LastModificationDate = vr_now
		WHERE ApplicationID = vr_application_id AND ServerID = vr_serverID AND UserID = vr_user_id
	END
	ELSE BEGIN
		INSERT INTO usr_remote_servers (
			ApplicationID, ServerID, UserID, Name, URL, UserName, password, CreationDate
		)
		VALUES (vr_application_id, vr_serverID, vr_user_id, vr_name, vr_url, vr_username, vr_password, vr_now)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_remote_server;

CREATE PROCEDURE usr_remove_remote_server
	vr_application_id	UUID,
	vr_serverID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DELETE usr_remote_servers
	WHERE ApplicationID = vr_application_id AND ServerID = vr_serverID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_remote_servers;

CREATE PROCEDURE usr_get_remote_servers
	vr_application_id	UUID,
	vr_serverID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT s.server_id, s.user_id, s.name, s.url, s.username, s.password
	FROM usr_remote_servers AS s
	WHERE s.application_id = vr_application_id AND 
		(vr_serverID IS NULL OR ServerID = vr_serverID)
	ORDER BY s.creation_date DESC
END;


-- Profile

DROP PROCEDURE IF EXISTS usr_p_save_password_history_bulk;

CREATE PROCEDURE usr_p_save_password_history_bulk
    vr_itemsTemp		GuidStringTableType readonly,
    vr_autoGenerated BOOLEAN,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_items GuidStringTableType
	INSERT INTO vr_items SELECT * FROM vr_itemsTemp
	
	INSERT INTO usr_passwords_history(
		UserID,
		password,
		set_date,
		AutoGenerated
	)
	SELECT	i.first_value,
			i.second_value,
			vr_now,
			COALESCE(vr_autoGenerated, 0)
	FROM vr_items AS i

	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_p_save_password_history;

CREATE PROCEDURE usr_p_save_password_history
    vr_user_id 		UUID,
    vr_password	 VARCHAR(255),
    vr_autoGenerated BOOLEAN,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO usr_passwords_history(
		UserID,
		password,
		set_date,
		AutoGenerated
	)
	VALUES(
		vr_user_id,
		vr_password,
		vr_now,
		COALESCE(vr_autoGenerated, 0)
	)

	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_last_passwords;

CREATE PROCEDURE usr_get_last_passwords
    vr_user_id 		UUID,
    vr_autoGenerated BOOLEAN,
    vr_count		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000)) password, AutoGenerated
	FROM usr_passwords_history
	WHERE UserID = vr_user_id AND (vr_autoGenerated IS NULL OR ISNULL.auto_generated, FALSE = vr_autoGenerated)
	ORDER BY ID DESC
END;


DROP PROCEDURE IF EXISTS usr_get_last_password_date;

CREATE PROCEDURE usr_get_last_password_date
    vr_user_id 		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) SetDate
	FROM usr_passwords_history
	WHERE UserID = vr_user_id
	ORDER BY ID DESC
END;


DROP PROCEDURE IF EXISTS usr_get_current_password;

CREATE PROCEDURE usr_get_current_password
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) m.password, m.password_salt
	FROM rv_membership AS m
	WHERE m.user_id = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_p_create_users;

CREATE PROCEDURE usr_p_create_users
	vr_application_id	UUID,
	vr_usersTemp		ExchangeUserTableType readonly,
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output,
    vr__error_message VARCHAR(255) output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_users ExchangeUserTableType
	INSERT INTO vr_users SELECT * FROM vr_usersTemp
	
	
	IF vr_application_id IS NOT NULL AND EXISTS(
		SELECT TOP(1) 1 
		FROM vr_users AS ref
			INNER JOIN users_normal AS u
			ON (vr_application_id IS NULL OR u.application_id = vr_application_id) AND 
				u.lowered_username = LOWER(ref.username)
	) BEGIN
		SET vr__result = -1
		SET vr__error_message = N'UserNameAlreadyExists'
		RETURN
	END
	ELSE IF vr_application_id IS NULL AND EXISTS(
		SELECT TOP(1) 1 
		FROM vr_users AS ref
			INNER JOIN rv_users AS u
			ON u.lowered_username = LOWER(ref.username)
	) BEGIN
		SET vr__result = -1
		SET vr__error_message = N'UserNameAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM vr_users AS ref
			INNER JOIN usr_email_addresses AS e
			ON LOWER(EmailAddress) = LOWER(ref.email) AND e.deleted = FALSE
			INNER JOIN usr_profile AS p
			ON p.user_id = e.user_id AND p.main_email_id = e.email_id
		WHERE COALESCE(ref.email, N'') <> N''
	) BEGIN
		SELECT vr__result = -1, vr__error_message = N'EmailAddressAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM vr_users AS ref
			INNER JOIN usr_phone_numbers AS e
			ON e.phone_number = LOWER(ref.phone_number) AND e.deleted = FALSE
			INNER JOIN usr_profile AS p
			ON p.user_id = e.user_id AND p.main_phone_id = e.number_id
		WHERE COALESCE(ref.phone_number, N'') <> N''
	) BEGIN
		SELECT vr__result = -1, vr__error_message = N'PhoneNumberAlreadyExists'
		RETURN
	END
	
	INSERT INTO rv_users(
		UserId,
		UserName,
		LoweredUserName,
		IsAnonymous,
		LastActivityDate
	)
	SELECT	ref.user_id, 
			ref.username, 
			LOWER(ref.username), 
			0, 
			N'1754-01-01 00:00:00.000'
	FROM vr_users AS ref
	WHERE ref.user_id IS NOT NULL AND COALESCE(ref.username, N'') <> N'' AND
		COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N''

	INSERT INTO rv_membership(
		UserId,
		password,
		PasswordFormat,
		PasswordSalt,
		IsApproved,
		IsLockedOut,
		CreateDate,
		LastLoginDate,
		LastPasswordChangedDate,
		LastLockoutDate,
		FailedPasswordAttemptCount,
		FailedPasswordAttemptWindowStart,
		FailedPasswordAnswerAttemptCount,
		FailedPasswordAnswerAttemptWindowStart
	)
	SELECT	ref.user_id,
			ref.password,
			N'1',
			ref.password_salt,
			1,
			0,
			vr_now,
			N'1754-01-01 00:00:00.000',
			N'1754-01-01 00:00:00.000',
			N'1754-01-01 00:00:00.000',
			0,
			N'1754-01-01 00:00:00.000',
			0,
			N'1754-01-01 00:00:00.000'
	FROM vr_users AS ref
	WHERE ref.user_id IS NOT NULL AND COALESCE(ref.username, N'') <> N'' AND
		COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N''
	
	INSERT INTO usr_profile(
		UserID, 
		FirstName, 
		LastName
	)
	SELECT	ref.user_id,
			ref.first_name,
			ref.last_name
	FROM vr_users AS ref
	WHERE ref.user_id IS NOT NULL AND COALESCE(ref.username, N'') <> N'' AND
		COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N''
	
	IF vr_application_id IS NOT NULL BEGIN
		INSERT INTO usr_user_applications(
			ApplicationID,
			UserID
		)
		SELECT	vr_application_id,
				ref.user_id
		FROM vr_users AS ref
		WHERE ref.user_id IS NOT NULL AND COALESCE(ref.username, N'') <> N'' AND
			COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N''
	END
	
	
	-- Update Email Addresses
	DECLARE vr_emails TABLE (UserID UUID, EmailID UUID, Email varchar(100))
	
	INSERT INTO vr_emails (UserID, EmailID, Email)
	SELECT ref.user_id, gen_random_uuid(), ref.email
	FROM vr_users AS ref
	WHERE ref.user_id IS NOT NULL AND COALESCE(ref.username, N'') <> N'' AND
		COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N'' AND
		COALESCE(ref.email, N'') <> N''
		
	INSERT INTO usr_email_addresses(
		EmailID, 
		UserID, 
		EmailAddress,
		CreatorUserID, 
		CreationDate, 
		Validated,
		Deleted
	)
	SELECT	e.email_id,
			e.user_id,
			LOWER(e.email),
			e.user_id,
			vr_now,
			1,
			0
	FROM vr_emails AS e
	
	UPDATE P
		SET MainEmailID = e.email_id
	FROM vr_emails AS e
		INNER JOIN usr_profile AS p
		ON p.user_id = e.user_id
	-- end of Update Email Addresses
	
	
	-- Update Phone Numbers
	DECLARE vr_numbers TABLE (UserID UUID, NumberID UUID, PhoneNumber varchar(100))
	
	INSERT INTO vr_numbers(UserID, NumberID, PhoneNumber)
	SELECT ref.user_id, gen_random_uuid(), ref.phone_number
	FROM vr_users AS ref
	WHERE ref.user_id IS NOT NULL AND COALESCE(ref.username, N'') <> N'' AND
		COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N'' AND
		COALESCE(ref.phone_number, N'') <> N''
		
	INSERT INTO usr_phone_numbers(
		NumberID, 
		UserID, 
		PhoneNumber,
		CreatorUserID, 
		CreationDate, 
		Validated,
		Deleted
	)
	SELECT	e.number_id,
			e.user_id,
			e.phone_number,
			e.user_id,
			vr_now,
			1,
			0
	FROM vr_numbers AS e
	
	UPDATE P
		SET MainPhoneID = e.number_id
	FROM vr_numbers AS e
		INNER JOIN usr_profile AS p
		ON p.user_id = e.user_id
	-- end of Update Phone Numbers
	
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS usr_create_user;

CREATE PROCEDURE usr_create_user
	vr_application_id		UUID,
    vr_user_id 			UUID,
    vr_username		 VARCHAR(255),
    vr_first_name		 VARCHAR(255),
    vr_last_name		 VARCHAR(255),
    vr_password		 VARCHAR(255),
    vr_passwordSalt	 VARCHAR(255),
    vr_encrypted_password VARCHAR(255),
    vr_pass_auto_generated BOOLEAN,
    vr_email				varchar(100),
    vr_phone_number		varchar(50),
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER, vr__error_message VARCHAR(255)
	
	DECLARE vr_users ExchangeUserTableType
	
	INSERT INTO vr_users (UserID, UserName, FirstName, LastName, 
		password, PasswordSalt, EncryptedPassword, Email, PhoneNumber)
	VALUES (vr_user_id, vr_username, vr_first_name, vr_last_name,
		vr_password, vr_passwordSalt, vr_encrypted_password, vr_email, vr_phone_number)
	
	EXEC usr_p_create_users vr_application_id, vr_users, vr_now, 
		vr__result output, vr__error_message output
	
	IF vr__result <= 0 BEGIN
		SELECT vr__result, vr__error_message
		ROLLBACK TRANSACTION
		RETURN
	END
	
	EXEC usr_p_save_password_history vr_user_id, vr_encrypted_password, vr_pass_auto_generated, vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SET vr__error_message = NULL
		SELECT vr__result, vr__error_message
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT vr__result, vr__error_message
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS usr_create_temporary_user;

CREATE PROCEDURE usr_create_temporary_user
    vr_user_id 			UUID,
    vr_username		 VARCHAR(255),
    vr_first_name		 VARCHAR(255),
    vr_last_name		 VARCHAR(255),
    vr_password		 VARCHAR(255),
    vr_passwordSalt	 VARCHAR(255),
    vr_encrypted_password VARCHAR(255),
    vr_pass_auto_generated BOOLEAN,
    vr_email			 VARCHAR(255),
    vr_phone_number		varchar(50),
    vr_now			 TIMESTAMP,
    vr_expiration_date	 TIMESTAMP,
    vr_activationCode		varchar(255),
    vr_invitationID		UUID
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_username = gfn_verify_string(vr_username)
	SET vr_first_name = gfn_verify_string(vr_first_name)
	SET vr_last_name = gfn_verify_string(vr_last_name)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM usr_view_users 
		WHERE LoweredUserName = LOWER(vr_username)
	) OR EXISTS(
		SELECT TOP(1) 1 
		FROM usr_temporary_users 
		WHERE LOWER(UserName) = LOWER(vr_username) AND
			(ExpirationDate IS NOT NULL AND ExpirationDate >= vr_now)
	) BEGIN
		SELECT -1, N'UserNameAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM usr_email_addresses  AS e
		WHERE LOWER(e.email_address) = LOWER(vr_email)
	) BEGIN
		SELECT -1, N'EmailAddressAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM usr_phone_numbers  AS e
		WHERE LOWER(e.phone_number) = LOWER(vr_phone_number)
	) BEGIN
		SELECT -1, N'PhoneNumberAlreadyExists'
		RETURN
	END
	
	
	INSERT INTO usr_temporary_users(
		UserID,
		UserName,
		FirstName,
		LastName,
		password,
		PasswordSalt,
		EMail,
		PhoneNumber,
		CreationDate,
		ExpirationDate,
		ActivationCode
	)
	VALUES(
		vr_user_id,
		vr_username,
		vr_first_name,
		vr_last_name,
		vr_password,
		vr_passwordSalt,
		vr_email,
		vr_phone_number,
		vr_now,
		vr_expiration_date,
		vr_activationCode
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_invitationID IS NOT NULL BEGIN
		UPDATE usr_invitations
			SET CreatedUserID = vr_user_id
		WHERE ID = vr_invitationID
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE vr__result INTEGER
	
	EXEC usr_p_save_password_history vr_user_id, vr_encrypted_password, vr_pass_auto_generated, vr_now, vr__result output
		
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS usr_activate_temporary_user;

CREATE PROCEDURE usr_activate_temporary_user
    vr_activationCode	VARCHAR(255),
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_id UUID, vr_username VARCHAR(255), vr_first_name VARCHAR(255),
		vr_last_name VARCHAR(255), vr_password VARCHAR(255), vr_passwordSalt VARCHAR(255),
		vr_email VARCHAR(255), vr_phone_number varchar(50), vr_application_id	UUID
		
	IF (
		SELECT TOP(1) 1 
		FROM usr_view_users
		WHERE UserID = vr_user_id
	) IS NOT NULL BEGIN
		SELECT 1
		RETURN
	END
	
	SELECT TOP(1)	
			vr_user_id = t.user_id, vr_username = t.username, vr_first_name = t.first_name, vr_last_name = t.last_name,
			vr_email = t.email, vr_phone_number = t.phone_number, vr_password = t.password, vr_passwordSalt = t.password_salt,
			vr_application_id = i.application_id
	FROM usr_temporary_users AS t
		LEFT JOIN usr_invitations AS i
		ON i.created_user_id = t.user_id
	WHERE t.activation_code = vr_activationCode
	
	DECLARE vr__result INTEGER, vr__error_message VARCHAR(255)
	
	DECLARE vr_users ExchangeUserTableType
	
	INSERT INTO vr_users (UserID, UserName, FirstName, LastName, 
		password, PasswordSalt, EncryptedPassword, Email, PhoneNumber)
	VALUES (vr_user_id, vr_username, vr_first_name, vr_last_name,
		vr_password, vr_passwordSalt, vr_password, vr_email, vr_phone_number)
	
	EXEC usr_p_create_users vr_application_id, vr_users, vr_now, 
		vr__result output, vr__error_message output
	
	SELECT vr__result, vr__error_message
END;


DROP PROCEDURE IF EXISTS usr_get_invitation_id;

CREATE PROCEDURE usr_get_invitation_id
	vr_application_id	UUID,
	vr_email		 VARCHAR(255),
	vr_check_if_not_used BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT i.id
	FROM usr_invitations AS i
	WHERE i.application_id = vr_application_id AND i.email = LOWER(vr_email) AND
		(COALESCE(vr_check_if_not_used, 0) = 0 OR i.created_user_id IS NULL)
END;


DROP PROCEDURE IF EXISTS usr_invite_user;

CREATE PROCEDURE usr_invite_user
	vr_application_id	UUID,
	vr_invitationID	UUID,
	vr_email		 VARCHAR(255),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_email = LOWER(vr_email)

	INSERT INTO usr_invitations (
		ApplicationID,
		ID, 
		Email, 
		SenderUserID, 
		SendDate
	)
	VALUES (vr_application_id, vr_invitationID, LOWER(vr_email), vr_current_user_id, vr_now)

	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_invited_users_count;

CREATE PROCEDURE usr_get_invited_users_count
	vr_application_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(Email)
	FROM usr_invitations
	WHERE ApplicationID = vr_application_id AND vr_user_id IS NULL OR SenderUserID = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_get_user_invitations;

CREATE PROCEDURE usr_get_user_invitations
	vr_application_id		UUID,
	vr_senderUserID		UUID,
	vr_count			 INTEGER,
	vr_lower_boundary		BIGINT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_results TABLE (
		Email VARCHAR(255), 
		SendDate TIMESTAMP, 
		UserID UUID,
		FirstName VARCHAR(200),
		LastName VARCHAR(200),
		Activated BOOLEAN
	)
	
	
	-- Email Based Results
	INSERT INTO vr_results (Email, SendDate, UserID, FirstName, LastName, Activated)
	SELECT	LOWER(i.email), 
			MAX(i.send_date),
			CAST(MAX(CAST(un.user_id AS varchar(50))) AS uuid),
			MAX(un.first_name),
			MAX(un.last_name),
			1 AS activated
	FROM usr_invitations AS i
		INNER JOIN users_normal AS un
		ON i.application_id = un.application_id
		INNER JOIN usr_email_addresses AS ea
		ON ea.user_id = un.user_id AND LOWER(ea.email_address) = LOWER(i.email)
	WHERE i.application_id = vr_application_id AND i.sender_user_id = vr_senderUserID
	GROUP BY LOWER(i.email)
	-- end of Email Based Results
	
	
	-- Temp User Based Results
	INSERT INTO vr_results (Email, SendDate, UserID, FirstName, LastName, Activated)
	SELECT x.email, x.send_date, x.user_id, x.first_name, x.last_name, x.activated
	FROM (
			SELECT	LOWER(i.email) AS email, 
					MAX(i.send_date) AS send_date,
					CAST(MAX(CAST(t.user_id AS varchar(50))) AS uuid) AS user_id,
					MAX(t.first_name) AS first_name,
					MAX(t.last_name) AS last_name,
					MAX(CASE WHEN p.user_id IS NULL THEN 0 ELSE 1 END) AS activated
			FROM usr_invitations AS i
				INNER JOIN usr_temporary_users AS t
				ON t.user_id = i.created_user_id
				LEFT JOIN usr_profile AS p
				ON p.user_id = t.user_id
			WHERE i.application_id = vr_application_id AND i.sender_user_id = vr_senderUserID
			GROUP BY LOWER(i.email)
		) AS x
		LEFT JOIN vr_results AS r
		ON r.email = x.email
	WHERE r.email IS NULL
	-- end of Temp User Based Results
	
	
	-- Not Activated Invites
	INSERT INTO vr_results (Email, SendDate, UserID, FirstName, LastName, Activated)
	SELECT x.email, x.send_date, NULL, NULL, NULL, 0
	FROM (
			SELECT	LOWER(i.email) AS email, 
					MAX(i.send_date) AS send_date
			FROM usr_invitations AS i
			WHERE i.application_id = vr_application_id AND i.sender_user_id = vr_senderUserID
			GROUP BY LOWER(i.email)
		) AS x
		LEFT JOIN vr_results AS r
		ON r.email = x.email
	WHERE r.email IS NULL
	-- Not Activated Invites
	

	SELECT TOP(COALESCE(vr_count, 1000000000)) 
		t.user_id AS receiver_user_id,
		t.first_name AS receiver_first_name,
		t.last_name AS receiver_last_name,
		t.email,
		t.send_date,
		CAST(t.activated AS boolean) AS activated,
		t.row_num AS order,
		(t.rev_row_num + t.row_num - 1) AS total_count
	FROM(
		SELECT 
			r.user_id,
			r.first_name,
			r.last_name,
			r.email,
			r.send_date,
			r.activated,
			ROW_NUMBER() OVER (ORDER BY r.send_date DESC, r.user_id DESC) AS row_num,
			ROW_NUMBER() OVER (ORDER BY r.send_date ASC, r.user_id ASC) AS rev_row_num
		FROM vr_results AS r
	) AS t
	WHERE t.row_num >= COALESCE(vr_lower_boundary,0)
	ORDER BY t.row_num ASC
END;


DROP PROCEDURE IF EXISTS usr_get_current_invitations;

CREATE PROCEDURE usr_get_current_invitations
	vr_user_id			UUID,
	vr_email		 VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT app_ids.application_id AS id
	FROM (
			SELECT DISTINCT i.application_id
			FROM usr_invitations AS i
			WHERE LOWER(i.email) = LOWER(vr_email)
		) AS app_ids
		LEFT JOIN usr_user_applications AS a
		ON a.application_id = app_ids.application_id AND a.user_id = vr_user_id
	WHERE a.user_id IS NULL
	

END;


DROP PROCEDURE IF EXISTS usr_get_invitation_application_id;

CREATE PROCEDURE usr_get_invitation_application_id
	vr_invitationID		UUID,
	vr_check_if_not_used	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT i.application_id AS id
	FROM usr_invitations AS i
	WHERE i.id = vr_invitationID AND (COALESCE(vr_check_if_not_used, 0) = 0 OR i.created_user_id IS NULL)
END;


DROP PROCEDURE IF EXISTS usr_set_pass_reset_ticket;

CREATE PROCEDURE usr_set_pass_reset_ticket
	vr_user_id			UUID,
    vr_ticket			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM usr_pass_reset_tickets 
		WHERE UserID = vr_user_id
	) BEGIN
		UPDATE usr_pass_reset_tickets
			SET Ticket = vr_ticket
		WHERE UserID = vr_user_id
	END
	ELSE BEGIN
		INSERT INTO usr_pass_reset_tickets(
			UserID,
			Ticket
		)
		VALUES(
			vr_user_id,
			vr_ticket
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_pass_reset_ticket;

CREATE PROCEDURE usr_get_pass_reset_ticket
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Ticket AS id
	FROM usr_pass_reset_tickets
	WHERE UserID = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_p_set_first_and_last_name;

CREATE PROCEDURE usr_p_set_first_and_last_name
    vr_user_id 		UUID,
    vr_first_name	 VARCHAR(255),
    vr_last_name	 VARCHAR(255),
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_first_name = gfn_verify_string(vr_first_name)
	SET vr_last_name = gfn_verify_string(vr_last_name)

	IF EXISTS(SELECT TOP(1) * FROM usr_profile WHERE UserID = vr_user_id) BEGIN
		UPDATE usr_profile
			SET FirstName = vr_first_name,
				LastName = vr_last_name
		WHERE UserId = vr_user_id
	END
	ELSE BEGIN
		INSERT INTO usr_profile(
			UserID,
			FirstName,
			LastName
		)
		VALUES(
			vr_user_id,
			vr_first_name,
			vr_last_name
		)
	END
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_first_and_last_name;

CREATE PROCEDURE usr_set_first_and_last_name
    vr_user_id 		UUID,
    vr_first_name	 VARCHAR(255),
    vr_last_name	 VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC usr_p_set_first_and_last_name vr_user_id, vr_first_name, vr_last_name, vr__result output

	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS usr_set_username;

CREATE PROCEDURE usr_set_username
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_username	 VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_username IS NOT NULL AND vr_username <> N'' AND NOT EXISTS (
		SELECT TOP(1) * 
		FROM users_normal
		WHERE ApplicationID = vr_application_id AND 
			LoweredUserName = LOWER(vr_username) AND UserId <> vr_user_id
	) BEGIN
		UPDATE rv_users
			SET UserName = vr_username,
				LoweredUserName = LOWER(vr_username)
		WHERE UserId = vr_user_id
		
		SELECT @vr_rowcount
	END
	ELSE BEGIN
		SELECT -1
	END
END;


DROP PROCEDURE IF EXISTS usr_set_password;

CREATE PROCEDURE usr_set_password
    vr_user_id 			UUID,
    vr_password		 VARCHAR(255),
    vr_passwordSalt	 VARCHAR(255),
    vr_encrypted_password VARCHAR(255),
    vr_autoGenerated	 BOOLEAN,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE rv_membership
		SET password = vr_password,
			PasswordSalt = vr_passwordSalt,
			IsLockedOut = 0
	WHERE UserId = vr_user_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr__result INTEGER
	
	EXEC usr_p_save_password_history vr_user_id, vr_encrypted_password, vr_autoGenerated, vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS usr_locked;

CREATE PROCEDURE usr_locked
    vr_user_id 		UUID,
    vr_locked		 BOOLEAN,
    vr_now		 TIMESTAMP	
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_locked IS NULL BEGIN
		SELECT TOP(1) m.user_id AS user_id, m.is_locked_out, m.last_lockout_date, m.is_approved
		FROM rv_membership AS m
		WHERE m.user_id = vr_user_id
	END
	ELSE BEGIN
		UPDATE M
			SET IsLockedOut = vr_locked,
				LastLockoutDate = CASE WHEN vr_locked = 1 THEN vr_now ELSE LastLockoutDate END,
				FailedPasswordAttemptCount = 
					(CASE WHEN m.is_locked_out = vr_locked THEN FailedPasswordAttemptCount ELSE 0 END)
		FROM rv_membership AS m
		WHERE m.user_id = vr_user_id
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS usr_login_attempt;

CREATE PROCEDURE usr_login_attempt
    vr_user_id 		UUID,
    vr_succeed	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE M
		SET FailedPasswordAttemptCount = 
				(CASE WHEN COALESCE(vr_succeed, 0) = 0 THEN COALESCE(FailedPasswordAttemptCount, 0) + 1 ELSE 0 END)
	FROM rv_membership AS m
	WHERE m.user_id = vr_user_id
		
		
	SELECT TOP(1) 
		(CASE WHEN m.failed_password_attempt_count <= 0 THEN 1 ELSE m.failed_password_attempt_count END) AS value
	FROM rv_membership AS m
	WHERE m.user_id = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_is_approved;

CREATE PROCEDURE usr_is_approved
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_isApproved	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_isApproved IS NULL BEGIN
		SELECT TOP(1) IsApproved
		FROM rv_membership AS m
		WHERE UserId = vr_user_id
	END
	ELSE BEGIN
		UPDATE rv_membership
			SET IsApproved = vr_isApproved
		WHERE UserId = vr_user_id
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS usr_set_birthday;

CREATE PROCEDURE usr_set_birthday
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_birthday	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET BirthDay = vr_birthday
	WHERE UserId = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_about_me;

CREATE PROCEDURE usr_set_about_me
    vr_user_id UUID,
    vr_text VARCHAR(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_text = gfn_verify_string(vr_text)
	
	UPDATE usr_profile
		SET AboutMe = vr_text
	WHERE  UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_city;

CREATE PROCEDURE usr_set_city
    vr_user_id UUID,
    vr_city VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_city = gfn_verify_string(vr_city)
	
	UPDATE usr_profile
		SET City = vr_city
	WHERE  UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_organization;

CREATE PROCEDURE usr_set_organization
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_organization VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_organization = gfn_verify_string(vr_organization)
	
	UPDATE usr_user_applications
		SET Organization = vr_organization
	WHERE  ApplicationID = vr_application_id AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_department;

CREATE PROCEDURE usr_set_department
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_department	 VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_department = gfn_verify_string(vr_department)
	
	UPDATE usr_user_applications
		SET Department = vr_department
	WHERE  ApplicationID = vr_application_id AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_job_title;

CREATE PROCEDURE usr_set_job_title
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_job_title	 VARCHAR(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_job_title = gfn_verify_string(vr_job_title)
	
	UPDATE usr_user_applications
		SET JobTitle = vr_job_title
	WHERE  ApplicationID = vr_application_id AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_employment_type;

CREATE PROCEDURE usr_set_employment_type
	vr_application_id	UUID,
    vr_user_id 		UUID,
    vr_employment_type	varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_user_applications
		SET EmploymentType = vr_employment_type
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_phone_number;

CREATE PROCEDURE usr_set_phone_number
	vr_numberID			UUID,
    vr_user_id 			UUID,
    vr_phone_number		varchar(50),
    vr_phone_numberType	varchar(20),
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO USR_PhoneNumbers(
		NumberID,
		PhoneNumber,
		UserID,
		CreatorUserID,
		CreationDate,
		PhoneType, 
		Deleted
	)
	VALUES (
		vr_numberID,
		vr_phone_number,
		vr_user_id,
		vr_creator_user_id,
		vr_creation_date,
		vr_phone_numberType,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_phone_numbers;

CREATE PROCEDURE usr_get_phone_numbers
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			NumberID, 
			PhoneNumber, 
			PhoneType
	FROM usr_phone_numbers
	WHERE UserID = vr_user_id AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_phone_number;

CREATE PROCEDURE usr_get_phone_number
	vr_numberID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			NumberID, 
			PhoneNumber, 
			PhoneType
	FROM usr_phone_numbers
	WHERE NumberID = vr_numberID
END;


DROP PROCEDURE IF EXISTS usr_edit_phone_number;

CREATE PROCEDURE usr_edit_phone_number
	vr_numberID				UUID,
	vr_phone_number			VARCHAR(50),
	vr_phone_type				VARCHAR(20),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_phone_numbers
		SET PhoneNumber = vr_phone_number,
			PhoneType = vr_phone_type,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE NumberID = vr_numberID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_phone_number;

CREATE PROCEDURE usr_remove_phone_number
	vr_numberID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET MainPhoneID = null
	WHERE MainPhoneID = vr_numberID
	
	UPDATE usr_phone_numbers
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE NumberID = vr_numberID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_main_phone;

CREATE PROCEDURE usr_set_main_phone
	vr_numberID		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET MainPhoneID = vr_numberID
	WHERE UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_main_phone;

CREATE PROCEDURE usr_get_main_phone
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT MainPhoneID AS id
	FROM usr_profile
	WHERE UserID = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_set_email_address;

CREATE PROCEDURE usr_set_email_address
	vr_emailID		UUID,
    vr_user_id 		UUID,
    vr_emailAddress	varchar(100),
	vr_isMainEmail BOOLEAN,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO USR_EmailAddresses(
		EmailID,
		EmailAddress,
		UserID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		vr_emailID,
		vr_emailAddress,
		vr_user_id,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	DECLARE vr_result INTEGER = @vr_rowcount
	
	IF vr_isMainEmail = 1 BEGIN
		UPDATE usr_profile
			SET MainEmailID = vr_emailID
		WHERE UserID = vr_user_id
	END

	SELECT vr_result
END;


DROP PROCEDURE IF EXISTS usr_get_email_addresses;

CREATE PROCEDURE usr_get_email_addresses
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			EmailID, 
			EmailAddress
	FROM usr_email_addresses
	WHERE UserID = vr_user_id AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_email_address;

CREATE PROCEDURE usr_get_email_address
	vr_emailID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			EmailID, 
			EmailAddress
	FROM usr_email_addresses
	WHERE EmailID = vr_emailID
END;


DROP PROCEDURE IF EXISTS usr_get_email_owners;

CREATE PROCEDURE usr_get_email_owners
	vr_strEmails		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_emails StringTableType
	
	INSERT INTO vr_emails
	SELECT ref.value 
	FROM gfn_str_to_string_table(vr_strEmails, vr_delimiter) AS ref

	SELECT	ea.user_id, 
			ea.email_id, 
			ea.email_address,
			CAST(CASE WHEN usr.user_id IS NULL THEN 0 ELSE 1 END AS boolean) AS is_main
	FROM vr_emails AS e
		INNER JOIN usr_email_addresses AS ea
		ON e.value = ea.email_address
		LEFT JOIN usr_profile AS usr
		ON usr.user_id = ea.user_id AND usr.main_email_id = ea.email_id
	WHERE ea.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_phone_owners;

CREATE PROCEDURE usr_get_phone_owners
	vr_strNumbers		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_numbers StringTableType
	
	INSERT INTO vr_numbers
	SELECT ref.value 
	FROM gfn_str_to_string_table(vr_strNumbers, vr_delimiter) AS ref

	SELECT	pn.user_id, 
			pn.number_id, 
			pn.phone_number,
			CAST(CASE WHEN usr.user_id IS NULL THEN 0 ELSE 1 END AS boolean) AS is_main
	FROM vr_numbers AS n
		INNER JOIN usr_phone_numbers AS pn
		ON n.value = pn.phone_number
		LEFT JOIN usr_profile AS usr
		ON usr.user_id = pn.user_id AND usr.main_phone_id = pn.number_id
	WHERE pn.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_not_existing_emails;

CREATE PROCEDURE usr_get_not_existing_emails
	vr_application_id	UUID,
    vr_emailsTemp		StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_emails StringTableType
	INSERT INTO vr_emails SELECT * FROM vr_emailsTemp
	
	IF vr_application_id IS NULL BEGIN
		SELECT e.value
		FROM vr_emails AS e
			LEFT JOIN usr_email_addresses AS a
			INNER JOIN usr_view_users AS un
			ON un.user_id = a.user_id
			ON LOWER(e.value) = LOWER(a.email_address) AND a.deleted = FALSE
		WHERE a.email_id IS NULL
	END
	ELSE BEGIN
		SELECT e.value
		FROM vr_emails AS e
			LEFT JOIN usr_email_addresses AS a
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = a.user_id
			ON LOWER(e.value) = LOWER(a.email_address) AND a.deleted = FALSE
		WHERE a.email_id IS NULL
	END
END;


DROP PROCEDURE IF EXISTS usr_edit_email_address;

CREATE PROCEDURE usr_edit_email_address
	vr_emailID				UUID,
	vr_address				VARCHAR(100),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE USR_EmailAddresses
		SET EmailAddress = vr_address,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE EmailID = vr_emailID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_email_address;

CREATE PROCEDURE usr_remove_email_address
	vr_emailID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET MainEmailID = null
	WHERE MainEmailID = vr_emailID
	
	UPDATE usr_email_addresses
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE EmailID = vr_emailID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_main_email;

CREATE PROCEDURE usr_set_main_email
	vr_emailID		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_profile
		SET MainEmailID = vr_emailID
	WHERE UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_main_email;

CREATE PROCEDURE usr_get_main_email
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT MainEmailID AS id
	FROM usr_profile
	WHERE UserID = vr_user_id
END;


DROP PROCEDURE IF EXISTS usr_get_users_main_email;

CREATE PROCEDURE usr_get_users_main_email
    vr_strUserIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	INSERT INTO vr_user_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	SELECT ea.email_id, un.user_id, ea.email_address
	FROM vr_user_ids AS u_ids
		INNER JOIN usr_profile AS un
		ON un.user_id = u_ids.value
		INNER JOIN usr_email_addresses AS ea
		ON ea.email_id = un.main_email_id
	WHERE ea.deleted = FALSE 
END;


DROP PROCEDURE IF EXISTS usr_get_users_main_phone;

CREATE PROCEDURE usr_get_users_main_phone
    vr_strUserIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	INSERT INTO vr_user_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	SELECT pn.number_id, un.user_id, pn.phone_number, pn.phone_type
	FROM vr_user_ids AS u_ids
		INNER JOIN usr_profile AS un
		ON un.user_id = u_ids.value
		INNER JOIN usr_phone_numbers AS pn
		ON pn.number_id = un.main_phone_id
	WHERE pn.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_job_experiences;

CREATE PROCEDURE usr_get_job_experiences
	vr_application_id UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		je.job_id, 
		je.user_id,
		je.title, 
		je.employer,
		je.start_date,
		je.end_date
	FROM usr_job_experiences AS je
	WHERE je.application_id = vr_application_id AND je.user_id = vr_user_id AND deleted = FALSE
	ORDER BY je.start_date DESC
END;


DROP PROCEDURE IF EXISTS usr_get_job_experience;

CREATE PROCEDURE usr_get_job_experience
	vr_application_id	UUID,
    vr_job_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		je.job_id, 
		je.user_id,
		je.title, 
		je.employer,
		je.start_date,
		je.end_date
	FROM usr_job_experiences AS je
	WHERE je.application_id = vr_application_id AND je.job_id = vr_job_id
END;


DROP PROCEDURE IF EXISTS usr_get_educational_experiences;

CREATE PROCEDURE usr_get_educational_experiences
	vr_application_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ee.education_id,
		ee.user_id,
		ee.school,
		ee.study_field,
		ee.level,
		ee.start_date,
		ee.end_date,
		ee.graduate_degree,
		ee.is_school
	FROM usr_educational_experiences AS ee
	WHERE ee.application_id = vr_application_id AND ee.user_id = vr_user_id AND deleted = FALSE
	ORDER BY ee.start_date DESC
END;


DROP PROCEDURE IF EXISTS usr_get_educational_experience;

CREATE PROCEDURE usr_get_educational_experience
	vr_application_id		UUID,
    vr_education_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ee.education_id,
		ee.user_id,
		ee.school,
		ee.study_field,
		ee.level,
		ee.start_date,
		ee.end_date,
		ee.graduate_degree,
		ee.is_school
	FROM usr_educational_experiences AS ee
	WHERE ee.application_id = vr_application_id AND ee.education_id = vr_education_id
END;


DROP PROCEDURE IF EXISTS usr_get_honors_and_awards;

CREATE PROCEDURE usr_get_honors_and_awards
	vr_application_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		hnr.id,
		hnr.user_id,
		hnr.title,
		hnr.issuer,
		hnr.occupation,
		hnr.issue_date,
		hnr.description
	FROM usr_honors_and_awards AS hnr
	WHERE hnr.application_id = vr_application_id AND hnr.user_id = vr_user_id AND deleted = FALSE
	ORDER BY hnr.issue_date DESC
END;


DROP PROCEDURE IF EXISTS usr_get_honor_or_award;

CREATE PROCEDURE usr_get_honor_or_award
	vr_application_id	UUID,
    vr_iD				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		hnr.id,
		hnr.user_id,
		hnr.title,
		hnr.issuer,
		hnr.occupation,
		hnr.issue_date,
		hnr.description
	FROM usr_honors_and_awards AS hnr
	WHERE hnr.application_id = vr_application_id AND hnr.id = vr_iD
END;


DROP PROCEDURE IF EXISTS usr_get_user_languages;

CREATE PROCEDURE usr_get_user_languages
	vr_application_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ul.id,
		ul.user_id,
		ln.language_name,
		ul.level
	FROM usr_user_languages AS ul
		INNER JOIN usr_language_names AS ln
		ON ln.application_id = vr_application_id AND ln.language_id = ul.language_id
	WHERE ul.application_id = vr_application_id AND ul.user_id = vr_user_id AND deleted = FALSE
	ORDER BY ln.language_name DESC
END;


DROP PROCEDURE IF EXISTS usr_get_user_language;

CREATE PROCEDURE usr_get_user_language
	vr_application_id	UUID,
    vr_iD				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ul.id,
		ul.user_id,
		ln.language_name,
		ul.level
	FROM usr_user_languages AS ul
		INNER JOIN usr_language_names AS ln
		ON ln.application_id = vr_application_id AND ln.language_id = ul.language_id
	WHERE ul.application_id = vr_application_id AND ul.id = vr_iD
END;


DROP PROCEDURE IF EXISTS usr_get_languages;

CREATE PROCEDURE usr_get_languages
	vr_application_id		UUID,
	vr_strLanguageIDs	 VARCHAR(MAX),
	vr_delimiter			CHAR
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_get_all AS boolean
	
	IF(vr_strLanguageIDs IS NULL) SET vr_get_all = 1
	ELSE SET vr_get_all = 0
	
	DECLARE vr_language_ids GuidTableType
	
	IF(vr_get_all = 0)
	BEGIN
		INSERT INTO vr_language_ids
		SELECT ref.value FROM gfn_str_to_guid_table(vr_strLanguageIDs, COALESCE(vr_delimiter,',')) AS ref
	END
	
	SELECT ln.language_id,
		ln.language_name
	FROM usr_language_names AS ln
		LEFT JOIN vr_language_ids AS l
		ON ln.language_id = l.value
	WHERE ln.application_id = vr_application_id AND (vr_get_all = 1 OR l.value = ln.language_id)
	ORDER BY ln.language_name
END;


DROP PROCEDURE IF EXISTS usr_set_job_experience;

CREATE PROCEDURE usr_set_job_experience
	vr_application_id	UUID,
	vr_job_id			UUID,
    vr_user_id			UUID,
    vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
    vr_title		 VARCHAR(256),
    vr_employer	 VARCHAR(256),
    vr_start_date	 TIMESTAMP,
    vr_end_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM usr_job_experiences 
		WHERE ApplicationID = vr_application_id AND JobID = vr_job_id
	) BEGIN
		UPDATE usr_job_experiences
			SET UserID = vr_user_id,
				Title = vr_title,
				Employer = vr_employer,
				StartDate = vr_start_date,
				EndDate = vr_end_date
		WHERE ApplicationID = vr_application_id AND JobID = vr_job_id
	END
	ELSE BEGIN
		INSERT INTO usr_job_experiences(
			ApplicationID,
			JobID,
			UserID,
			Title,
			Employer,
			StartDate,
			EndDate,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_job_id,
			vr_user_id,
			vr_title,
			vr_employer,
			vr_start_date,
			vr_end_date,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_educational_experience;

CREATE PROCEDURE usr_set_educational_experience
	vr_application_id	UUID,
	vr_education_id	UUID,
	vr_user_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr_school		 VARCHAR(256),
	vr_study_field	 VARCHAR(256),
	vr_level			VARCHAR(50),
	vr_graduate_degree	VARCHAR(50),
	vr_start_date	 TIMESTAMP,
	vr_end_date	 TIMESTAMP,
	vr_is_school	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM usr_educational_experiences 
		WHERE ApplicationID = vr_application_id AND EducationID = vr_education_id
	) BEGIN	
		UPDATE usr_educational_experiences
			SET UserID = vr_user_id,
				School = vr_school,
				StudyField = vr_study_field,
				level = vr_level,
				graduate_degree = vr_graduate_degree,
				StartDate = vr_start_date,
				EndDate = vr_end_date,
				CreatorUserID = vr_creator_user_id,
				CreationDate = vr_creation_date,
				IsSchool = vr_is_school
		WHERE ApplicationID = vr_application_id AND EducationID = vr_education_id
	END
	ELSE BEGIN
		INSERT INTO usr_educational_experiences(
			ApplicationID,
			EducationID,
			UserID,
			School,
			StudyField,
			level,
			graduate_degree,
			StartDate,
			EndDate,
			CreatorUserID,
			CreationDate,
			IsSchool,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_education_id,
			vr_user_id,
			vr_school,
			vr_study_field,
			vr_level,
			vr_graduate_degree,
			vr_start_date,
			vr_end_date,
			vr_creator_user_id,
			vr_creation_date,
			vr_is_school,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_honor_and_award;

CREATE PROCEDURE usr_set_honor_and_award
	vr_application_id	UUID,
	vr_honor_id		UUID,
	vr_user_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr_title		 VARCHAR(512),
	vr_occupation	 VARCHAR(512),
	vr_issuer		 VARCHAR(512),
	vr_issue_date	 TIMESTAMP,
	vr_description VARCHAR(MAX)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM usr_honors_and_awards 
		WHERE ApplicationID = vr_application_id AND ID = vr_honor_id
	) BEGIN
		UPDATE usr_honors_and_awards
			SET UserID = vr_user_id,
				Title = vr_title,
				Occupation = vr_occupation,
				Issuer = vr_issuer,
				IssueDate = vr_issue_date,
				description = vr_description,
				CreatorUserID = vr_creator_user_id,
				CreationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND ID = vr_honor_id
	END
	ELSE BEGIN
		INSERT INTO usr_honors_and_awards(
			ApplicationID,
			ID,
			UserID,
			Title,
			Occupation,
			Issuer,
			IssueDate,
			description,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_honor_id,
			vr_user_id,
			vr_title,
			vr_occupation,
			vr_issuer,
			vr_issue_date,
			vr_description,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_language;

CREATE PROCEDURE usr_set_language
	vr_application_id	UUID,
	vr_id				UUID,
	vr_language_name VARCHAR(256),
	vr_user_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr_level		 VARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_language_name = gfn_verify_string(vr_language_name)
	
	DECLARE vr_language_id UUID = (
		SELECT LanguageID 
		FROM usr_language_names 
		WHERE ApplicationID = vr_application_id AND LanguageName = vr_language_name
	)
	
	IF (vr_language_id IS NULL) BEGIN
		SET vr_language_id = gen_random_uuid()
		
		INSERT INTO usr_language_names(
			ApplicationID,
			LanguageID,
			LanguageName
		)
		VALUES(
			vr_application_id,
			vr_language_id,
			vr_language_name
		)
	END
		
	IF EXISTS(
		SELECT TOP(1) * 
		FROM usr_user_languages 
		WHERE ApplicationID = vr_application_id AND ID = vr_id
	) BEGIN
		UPDATE usr_user_languages
			SET UserID = vr_user_id,
				LanguageID = vr_language_id,
				level	= vr_level,
				CreatorUserID = vr_creator_user_id,
				CreationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND ID = vr_id
	END
	ELSE BEGIN
		INSERT INTO usr_user_languages(
			ApplicationID,
			ID,
			LanguageID,
			UserID,
			level,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_id,
			vr_language_id,
			vr_user_id,
			vr_level,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	ENd
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_job_experience;

CREATE PROCEDURE usr_remove_job_experience
	vr_application_id	UUID,
	vr_job_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_job_experiences
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND JobID = vr_job_id AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_educational_experience;

CREATE PROCEDURE usr_remove_educational_experience
	vr_application_id	UUID,
	vr_education_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_educational_experiences
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND EducationID = vr_education_id AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_honor_and_award;

CREATE PROCEDURE usr_remove_honor_and_award
	vr_application_id	UUID,
	vr_honor_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_honors_and_awards
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ID = vr_honor_id AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_language;

CREATE PROCEDURE usr_remove_language
	vr_application_id	UUID,
	vr_id				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_user_languages
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ID = vr_id AND deleted = FALSE
	
	SELECT @vr_rowcount
END;

-- end of Profile


-- User Groups

DROP PROCEDURE IF EXISTS usr_create_user_group;

CREATE PROCEDURE usr_create_user_group
	vr_application_id	UUID,
	vr_group_id		UUID,
	vr_title		 VARCHAR(512),
	vr_description VARCHAR(2000),
	vr_creator_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_description = gfn_verify_string(vr_description)
	
	INSERT usr_user_groups (
		ApplicationID,
		GroupID,
		Title,
		description,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		vr_application_id,
		vr_group_id,
		vr_title,
		vr_description,
		vr_creator_user_id,
		vr_now,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_modify_user_group;

CREATE PROCEDURE usr_modify_user_group
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_title			 VARCHAR(512),
	vr_description	 VARCHAR(2000),
	vr_last_modifier_user_id	UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE usr_user_groups
		SET Title = vr_title,
			description = vr_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_user_group;

CREATE PROCEDURE usr_remove_user_group
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_last_modifier_user_id	UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_user_groups
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_add_user_group_members;

CREATE PROCEDURE usr_add_user_group_members
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_strUserIDs			varchar(max),
	vr_delimiter			char,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_changed_count INTEGER = 0
	
	UPDATE M
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_user_ids AS u
		INNER JOIN usr_user_group_members AS m
		ON m.user_id = u.value
	WHERE m.application_id = vr_application_id AND m.group_id = vr_group_id
		
	SET vr_changed_count = @vr_rowcount
	
	INSERT INTO usr_user_group_members (
		ApplicationID,
		GroupID,
		UserID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, vr_group_id, u.value, vr_current_user_id, vr_now, 0
	FROM vr_user_ids AS u
		LEFT JOIN usr_user_group_members AS m
		ON m.application_id = vr_application_id AND m.group_id = vr_group_id AND m.user_id = u.value
	WHERE m.group_id IS NULL
	
	SELECT @vr_rowcount + vr_changed_count
END;


DROP PROCEDURE IF EXISTS usr_remove_user_group_members;

CREATE PROCEDURE usr_remove_user_group_members
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_strUserIDs			varchar(max),
	vr_delimiter			char,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_changed_count INTEGER = 0
	
	UPDATE M
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_user_ids AS u
		INNER JOIN usr_user_group_members AS m
		ON m.user_id = u.value
	WHERE m.application_id = vr_application_id AND m.group_id = vr_group_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_user_group_permission;

CREATE PROCEDURE usr_set_user_group_permission
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_role_id				UUID,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM usr_user_group_permissions
		WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id AND RoleID = vr_role_id
	) BEGIN
		UPDATE usr_user_group_permissions
			SET deleted = FALSE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id AND RoleID = vr_role_id
	END
	ELSE BEGIN
		INSERT INTO usr_user_group_permissions (
			ApplicationID,
			GroupID,
			RoleID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			vr_application_id,
			vr_group_id,
			vr_role_id,
			vr_current_user_id,
			vr_now,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_unset_user_group_permission;

CREATE PROCEDURE usr_unset_user_group_permission
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_role_id				UUID,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_user_group_permissions
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id AND RoleID = vr_role_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_user_groups;

CREATE PROCEDURE usr_get_user_groups
	vr_application_id		UUID,
	vr_strGroupIDs		varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_group_ids GuidTableType
	
	INSERT INTO vr_group_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref
	
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)
	
	SELECT	g.group_id,
			g.title,
			g.description
	FROM usr_user_groups AS g
	WHERE g.application_id = vr_application_id AND 
		(vr_groups_count = 0 OR g.group_id IN (SELECT ref.value FROM vr_group_ids AS ref)) AND
		g.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_user_group_members;

CREATE PROCEDURE usr_get_user_group_members
	vr_application_id		UUID,
	vr_group_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids KeyLessGuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT m.user_id
	FROM usr_user_groups AS g
		INNER JOIN usr_user_group_members AS m
		ON m.application_id = vr_application_id AND m.group_id = g.group_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = m.user_id
	WHERE g.application_id = vr_application_id AND g.group_id = vr_group_id AND
		m.deleted = FALSE AND un.is_approved = TRUE
		
	EXEC usr_p_get_users_by_ids vr_application_id, vr_user_ids
END;


DROP PROCEDURE IF EXISTS usr_p_get_access_roles_by_ids;

CREATE PROCEDURE usr_p_get_access_roles_by_ids
	vr_application_id	UUID,
	vr_role_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_role_ids GuidTableType
	INSERT INTO vr_role_ids SELECT * FROM vr_role_idsTemp
	
	SELECT a.role_id, a.name, a.title
	FROM vr_role_ids AS r
		INNER JOIN usr_access_roles AS a
		ON a.role_id = r.value
	WHERE a.application_id = vr_application_id
END;


DROP PROCEDURE IF EXISTS usr_get_access_roles;

CREATE PROCEDURE usr_get_access_roles
	vr_application_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_role_ids GuidTableType
	
	INSERT INTO vr_role_ids (Value)
	SELECT RoleID
	FROM usr_access_roles
	WHERE ApplicationID = vr_application_id
	
	EXEC usr_p_get_access_roles_by_ids vr_application_id, vr_role_ids
END;


DROP PROCEDURE IF EXISTS usr_get_user_group_access_roles;

CREATE PROCEDURE usr_get_user_group_access_roles
	vr_application_id		UUID,
	vr_group_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_role_ids GuidTableType
	
	INSERT INTO vr_role_ids (Value)
	SELECT DISTINCT r.role_id
	FROM usr_user_groups AS g
		INNER JOIN usr_user_group_permissions AS p
		ON p.application_id = vr_application_id AND p.group_id = g.group_id
		INNER JOIN usr_access_roles AS r
		ON r.application_id = vr_application_id AND r.role_id = p.role_id
	WHERE g.application_id = vr_application_id AND g.group_id = vr_group_id 
		AND g.deleted = FALSE AND p.deleted = FALSE
	
	EXEC usr_p_get_access_roles_by_ids vr_application_id, vr_role_ids
END;


DROP PROCEDURE IF EXISTS usr_check_user_group_permissions;

CREATE PROCEDURE usr_check_user_group_permissions
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_permissions_temp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_permissions StringTableType
	INSERT INTO vr_permissions SELECT * FROM vr_permissions_temp
	
	SELECT DISTINCT r.name AS value
	FROM usr_user_group_members AS m
		INNER JOIN usr_user_groups AS g
		ON g.application_id = vr_application_id AND g.group_id = m.group_id
		INNER JOIN usr_user_group_permissions AS p
		ON p.application_id = vr_application_id AND p.group_id = g.group_id
		INNER JOIN usr_access_roles AS r
		ON r.application_id = vr_application_id AND r.role_id = p.role_id
	WHERE m.application_id = vr_application_id AND m.user_id = vr_user_id AND 
		(LOWER(r.name) IN (SELECT LOWER(ref.value) FROM vr_permissions AS ref)) AND
		m.deleted = FALSE AND g.deleted = FALSE AND p.deleted = FALSE
END;

-- end of User Groups

DROP PROCEDURE IF EXISTS kw_p_initialize_forms;

CREATE PROCEDURE kw_p_initialize_forms
	vr_application_id		UUID,
	vr_adminID			UUID,
	vr_experience_type_id	UUID,
	vr_skillTypeID		UUID,
	vr_document_type_id		UUID,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_id UUID = NULL

	IF vr_experience_type_id IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) * 
		FROM fg_form_owners AS fo 
		WHERE fo.application_id = vr_application_id AND OwnerID = vr_experience_type_id
	) BEGIN
		SET vr_form_id = gen_random_uuid()

		INSERT fg_extended_forms (application_id, form_id, title, 
			creator_user_id, creation_date, deleted) 
		VALUES (vr_application_id, vr_form_id, N'فرم ثبت تجربه', vr_adminID, 
			CAST(0x0000A49600C3C29A AS timestamp), 0)
		
		INSERT fg_extended_form_elements (application_id, element_id, form_id, 
			title, sequence_number, type, info, creator_user_id, creation_date, 
			deleted, necessary) 
		VALUES (vr_application_id, gen_random_uuid(), vr_form_id, N'شرح تجربه', 7, N'Text', N'{}', 
			vr_adminID, CAST(0x0000A49600C7EB49 AS timestamp), 0, 1)
		
		INSERT fg_extended_form_elements (application_id, element_id, form_id, 
			title, sequence_number, type, info, creator_user_id, creation_date, 
			deleted, necessary) 
		VALUES (vr_application_id, gen_random_uuid(), vr_form_id, N'کاربرد تجربه', 9, N'Text', N'{}', 
			vr_adminID, CAST(0x0000A49600C82B85 AS timestamp), 0, 1)

		INSERT INTO fg_form_owners (ApplicationID, OwnerID, FormID, 
			CreatorUserID, CreationDate, Deleted)
		VALUES (vr_application_id, vr_experience_type_id, vr_form_id, vr_adminID, GETDATE(), 0)
	END


	IF vr_skillTypeID IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) * 
		FROM fg_form_owners AS fo 
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_skillTypeID
	) BEGIN
		SET vr_form_id = gen_random_uuid()

		INSERT fg_extended_forms (application_id, form_id, title, 
			creator_user_id, creation_date, deleted) 
		VALUES (vr_application_id, vr_form_id, N'فرم ثبت مهارت', vr_adminID, 
			CAST(0x0000A49600C3C29A AS timestamp), 0)
		
		INSERT fg_extended_form_elements (application_id, element_id, form_id, 
			title, sequence_number, type, info, creator_user_id, creation_date, 
			deleted, necessary) 
		VALUES (vr_application_id, gen_random_uuid(), vr_form_id, N'شرح مهارت', 7, N'Text', N'{}', 
			vr_adminID, CAST(0x0000A49600C7EB49 AS timestamp), 0, 1)
		
		INSERT fg_extended_form_elements (application_id, element_id, form_id, 
			title, sequence_number, type, info, creator_user_id, creation_date, 
			deleted, necessary) 
		VALUES (vr_application_id, gen_random_uuid(), vr_form_id, N'کاربرد مهارت', 9, N'Text', N'{}', 
			vr_adminID, CAST(0x0000A49600C82B85 AS timestamp), 0, 1)

		INSERT INTO fg_form_owners (ApplicationID, OwnerID, FormID, 
			CreatorUserID, CreationDate, Deleted)
		VALUES (vr_application_id, vr_skillTypeID, vr_form_id, vr_adminID, GETDATE(), 0)
	END


	IF vr_document_type_id IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) * 
		FROM fg_form_owners AS fo 
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_document_type_id
	) BEGIN
		SET vr_form_id = gen_random_uuid()

		INSERT fg_extended_forms (application_id, form_id, title, 
			creator_user_id, creation_date, deleted) 
		VALUES (vr_application_id, vr_form_id, N'فرم ثبت مستند', vr_adminID, 
			CAST(0x0000A49600C3C29A AS timestamp), 0)
		
		INSERT fg_extended_form_elements (application_id, element_id, form_id, 
			title, sequence_number, type, info, creator_user_id, creation_date, 
			deleted, necessary) 
		VALUES (vr_application_id, gen_random_uuid(), vr_form_id, N'شرح مستند', 7, N'Text', N'{}', 
			vr_adminID, CAST(0x0000A49600C7EB49 AS timestamp), 0, 1)
		
		INSERT fg_extended_form_elements (application_id, element_id, form_id, 
			title, sequence_number, type, info, creator_user_id, creation_date, 
			deleted, necessary) 
		VALUES (vr_application_id, gen_random_uuid(), vr_form_id, N'کاربرد مستند', 9, N'Text', N'{}', 
			vr_adminID, CAST(0x0000A49600C82B85 AS timestamp), 0, 1)

		INSERT INTO fg_form_owners (ApplicationID, OwnerID, FormID, 
			CreatorUserID, CreationDate, Deleted)
		VALUES (vr_application_id, vr_document_type_id, vr_form_id, vr_adminID, GETDATE(), 0)
	END
END;


DROP PROCEDURE IF EXISTS kw_p_initialize_knowledge_types;

CREATE PROCEDURE kw_p_initialize_knowledge_types
	vr_application_id		UUID,
	vr_adminID			UUID,
	vr_experience_type_id	UUID,
	vr_skillTypeID		UUID,
	vr_document_type_id		UUID,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_now TIMESTAMP = GETDATE()
	
	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM kw_knowledge_types
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_experience_type_id
	) BEGIN
		INSERT INTO kw_knowledge_types (ApplicationID, KnowledgeTypeID,
			EvaluationType, Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore,
			NodeSelectType, CreatorUserID, CreationDate, Deleted)
		VALUES (vr_application_id, vr_experience_type_id, N'EN', N'Experts',
			N'Evaluation', 10, 5, N'Free', vr_adminID, vr_now, 0)
	END
	
	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM kw_knowledge_types
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_skillTypeID
	) BEGIN	
		INSERT INTO kw_knowledge_types (ApplicationID, KnowledgeTypeID,
			EvaluationType, Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore,
			NodeSelectType, CreatorUserID, CreationDate, Deleted)
		VALUES (vr_application_id, vr_skillTypeID, N'EN', N'Experts',
			N'Evaluation', 10, 5, N'Free', vr_adminID, vr_now, 0)
	END
	
	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM kw_knowledge_types
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_document_type_id
	) BEGIN	
		INSERT INTO kw_knowledge_types (ApplicationID, KnowledgeTypeID,
			EvaluationType, Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore,
			NodeSelectType, CreatorUserID, CreationDate, Deleted)
		VALUES (vr_application_id, vr_document_type_id, N'EN', N'Experts',
			N'Evaluation', 10, 5, N'Free', vr_adminID, vr_now, 0)
	END
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS kw_p_initialize_questions;

CREATE PROCEDURE kw_p_initialize_questions
	vr_application_id		UUID,
	vr_adminID			UUID,
	vr_experience_type_id	UUID,
	vr_skillTypeID		UUID,
	vr_document_type_id		UUID,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM kw_questions 
		WHERE ApplicationID = vr_application_id
	) BEGIN
		SET vr__result = 1
		RETURN
	END
	
	DECLARE vr_now TIMESTAMP = GETDATE()
	
	DECLARE vr_tbl Table (TypeID UUID, SequenceNumber INTEGER,
		QuestionID UUID, Title VARCHAR(1000))
		
	INSERT INTO vr_tbl (TypeID, QuestionID, SequenceNumber, Title)
	VALUES (
		vr_experience_type_id, gen_random_uuid(), 1,
		N'اگر این تجربه برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این تجربه نیاز داشته باشید؟'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 2,
		N'انتقال و آموزش این تجربه چگونه است؟ (ساده و کم هزینه=1، سخت و پر هزینه=10)'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 3,
		N'تا چه اندازه این تجربه برای اجرای فرایندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 4,
		N'تجربه تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 5,
		N'سازمان اگر بخواهد این تجربه را از بیرون به خدمت بگیرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون تومان=10، بالای 100 میلیون تومان=10)'
	),
	(
		vr_experience_type_id, gen_random_uuid(), 6,
		N'میزان اعتبار و به روز بودن این نوع تجربه را چگونه ارزیابی می کنید؟ تا چه حد در شرایط فعلی نیز قابل استفاده است؟ (خیلی زیاد=10، خیلی کم=1)'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 7,
		N'اگر این مهارت برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این مهارت نیاز پیدا شود؟'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 8,
		N'انتقال و آموزش این مهارت چگونه است؟ (ساده و کم هزینه=1، سخت و پر هزینه=10)'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 9,
		N'بنابر شواهد ارایه شده و با توجه به وضعیت فعلی سازمان، مهارت این فرد در چه سطحی است؟'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 10,
		N'تا چه اندازه این مهارت برای اجرای فرآیندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 11,
		N'سازمان اگر بخواهد این مهارت را از بیرون به خدمت بگیرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون تومان=1، بالای 100 میلیون تومان=10)'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 12,
		N'مهارت تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		vr_skillTypeID, gen_random_uuid(), 13,
		N'میزان اعتبار و به روز بودن این نوع مهارت را چگونه ارزیابی می کنید؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 14,
		N'اگر این مستند برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این مستند نیاز پیدا شود؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 15,
		N'این مستند تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 16,
		N'تا چه اندازه این مستند برای اجرای فرآیندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 17,
		N'دانش های پیش نیاز درک و بکارگیری این سند تا چه حد درون آن گنجانده شده یا به آنها به خوبی ارجاع داده شده است؟'
	),
	(
		vr_document_type_id, gen_random_uuid(), 18,
		N'سازمان اگر بخواهد این مستند را از بیرون بخرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون=1، بالای 100 میلیون=10)'
	),
	(
		vr_document_type_id, gen_random_uuid(), 19,
		N'میزان ساخت یافتگی و قابلیت استفاده از دانش درون این مستند چقدر است؟'
	)
	
	
	INSERT INTO kw_questions (
		ApplicationID, QuestionID, Title, CreatorUserID, CreationDate, Deleted
	)
	SELECT vr_application_id, t.question_id, t.title, vr_adminID, vr_now, 0
	FROM vr_tbl AS t
	
	
	INSERT INTO kw_type_questions (
		ApplicationID, ID, KnowledgeTypeID, QuestionID, SequenceNumber, 
		CreatorUserID, CreationDate, Deleted
	)
	SELECT vr_application_id, gen_random_uuid(), t.type_id, t.question_id, t.sequence_number, 
		vr_adminID, vr_now, 0
	FROM vr_tbl AS t
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS kw_p_initialize_services;

CREATE PROCEDURE kw_p_initialize_services
	vr_application_id		UUID,
	vr_experience_type_id	UUID,
	vr_skillTypeID		UUID,
	vr_document_type_id		UUID,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM kw_knowledge_types AS kt
			INNER JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = kt.knowledge_type_id
		WHERE kt.application_id = vr_application_id
	) BEGIN
		SET vr__result = 1
		RETURN
	END
	
	INSERT INTO cn_services (ApplicationID, NodeTypeID, ServiceTitle,
		EnableContribution, AdminType, MaxAcceptableAdminLevel, EditableForAdmin,
		EditableForCreator, EditableForOwners, EditableForExperts, EditableForMembers,
		Deleted, IsDocument, IsKnowledge, EditSuggestion, IsTree, SequenceNumber)
	VALUES (vr_application_id, vr_experience_type_id, N'ثبت تجربه', 1, N'AreaAdmin',
		2, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0)
		
	INSERT INTO cn_services (ApplicationID, NodeTypeID, ServiceTitle,
		EnableContribution, AdminType, MaxAcceptableAdminLevel, EditableForAdmin,
		EditableForCreator, EditableForOwners, EditableForExperts, EditableForMembers,
		Deleted, IsDocument, IsKnowledge, EditSuggestion, IsTree, SequenceNumber)
	VALUES (vr_application_id, vr_skillTypeID, N'ثبت مهارت', 0, N'AreaAdmin',
		2, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0)
		
	INSERT INTO cn_services (ApplicationID, NodeTypeID, ServiceTitle,
		EnableContribution, AdminType, MaxAcceptableAdminLevel, EditableForAdmin,
		EditableForCreator, EditableForOwners, EditableForExperts, EditableForMembers,
		Deleted, IsDocument, IsKnowledge, EditSuggestion, IsTree, SequenceNumber)
	VALUES (vr_application_id, vr_document_type_id, N'ثبت مستند', 1, N'AreaAdmin',
		2, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0)
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS kw_initialize;

CREATE PROCEDURE kw_initialize
	vr_application_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_experience_type_id UUID = (
		SELECT TOP(1) NodeTypeID
		FROM cn_node_types
		WHERE ApplicationID = vr_application_id AND AdditionalID = '9'
	)
	
	DECLARE vr_skillTypeID UUID = (
		SELECT TOP(1) NodeTypeID
		FROM cn_node_types
		WHERE ApplicationID = vr_application_id AND AdditionalID = '8'
	)
	
	DECLARE vr_document_type_id UUID = (
		SELECT TOP(1) NodeTypeID
		FROM cn_node_types
		WHERE ApplicationID = vr_application_id AND AdditionalID = '10'
	)
	
	DECLARE vr_adminID UUID = (
		SELECT TOP(1) UserID 
		FROM users_normal 
		WHERE ApplicationID = vr_application_id AND UserName = N'admin'
	)
	
	
	DECLARE vr__result INTEGER
	
	EXEC kw_p_initialize_forms vr_application_id, vr_adminID,
		vr_experience_type_id, vr_skillTypeID, vr_document_type_id, vr__result output
	
	EXEC kw_p_initialize_knowledge_types vr_application_id, vr_adminID,
		vr_experience_type_id, vr_skillTypeID, vr_document_type_id, vr__result output
	
	EXEC kw_p_initialize_questions vr_application_id, vr_adminID,
		vr_experience_type_id, vr_skillTypeID, vr_document_type_id, vr__result output
		
	EXEC kw_p_initialize_services vr_application_id, 
		vr_experience_type_id, vr_skillTypeID, vr_document_type_id, vr__result output
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS kw_add_knowledge_type;

CREATE PROCEDURE kw_add_knowledge_type
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE((
		SELECT TOP(1) 1
		FROM cn_services AS s
		WHERE s.application_id = vr_application_id AND 
			s.node_type_id = vr_knowledge_type_id AND COALESCE(s.is_knowledge, FALSE) = 1
	), 0) = 0 BEGIN
		SELECT -1
		RETURN
	END
	
	IF EXISTS(SELECT TOP(1) * FROM kw_knowledge_types 
		WHERE KnowledgeTypeID = vr_knowledge_type_id) BEGIN
		UPDATE kw_knowledge_types
			SET deleted = FALSE,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	END
	ELSE BEGIN
		INSERT INTO kw_knowledge_types(
			ApplicationID,
			KnowledgeTypeID,
			CreatorUserID,
			CreationDate,
			ConvertEvaluatorsToExperts,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_knowledge_type_id,
			vr_creator_user_id,
			vr_creation_date,
			0,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_arithmetic_delete_knowledge_type;

CREATE PROCEDURE kw_arithmetic_delete_knowledge_type
	vr_application_id				UUID,
	vr_knowledge_type_id			UUID,
	vr_last_modifier_user_id			UUID,
	vr_last_modification_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_p_get_knowledge_types_by_ids;

CREATE PROCEDURE kw_p_get_knowledge_types_by_ids
	vr_application_id			UUID,
	vr_knowledge_type_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_knowledge_type_ids GuidTableType
	INSERT INTO vr_knowledge_type_ids SELECT * FROM vr_knowledge_type_idsTemp
	
	SELECT kt.knowledge_type_id,
		   nt.name AS knowledge_type,
		   kt.node_select_type,
		   kt.evaluation_type,
		   kt.evaluators,
		   kt.pre_evaluate_by_owner,
		   kt.force_evaluators_describe,
		   kt.min_evaluations_count,
		   kt.searchable_after,
		   kt.score_scale,
		   kt.min_acceptable_score,
		   kt.convert_evaluators_to_experts,
		   kt.evaluations_editable,
		   kt.evaluations_editable_for_admin,
		   kt.evaluations_removable,
		   kt.unhide_evaluators,
		   kt.unhide_evaluations,
		   kt.unhide_node_creators,
		   kt.text_options,
		   nt.additional_id_pattern
	FROM vr_knowledge_type_ids AS ref
		INNER JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = ref.value
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ref.value
END;


DROP PROCEDURE IF EXISTS kw_get_knowledge_types;

CREATE PROCEDURE kw_get_knowledge_types
	vr_application_id			UUID,
	vr_strKnowledgeTypeIDs	varchar(max),
	vr_delimiter				char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_knowledge_type_ids GuidTableType
	
	INSERT INTO vr_knowledge_type_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strKnowledgeTypeIDs, vr_delimiter) AS ref
	
	IF (SELECT COUNT(*) FROM vr_knowledge_type_ids) = 1 BEGIN
		DECLARE vr_iD UUID = (SELECT TOP(1) * FROM vr_knowledge_type_ids)
		
		DELETE vr_knowledge_type_ids
		
		INSERT INTO vr_knowledge_type_ids (Value)
		SELECT COALESCE(
			(
				SELECT TOP(1) NodeTypeID 
				FROM cn_nodes 
				WHERE ApplicationID = vr_application_id AND NodeID = vr_iD
			), vr_iD)
	END
	
	IF (SELECT COUNT(*) FROM vr_knowledge_type_ids) = 0 BEGIN
		INSERT INTO vr_knowledge_type_ids
		SELECT KnowledgeTypeID
		FROM kw_knowledge_types
		WHERE ApplicationID = vr_application_id AND deleted = FALSE
	END
	
	EXEC kw_p_get_knowledge_types_by_ids vr_application_id, vr_knowledge_type_ids
END;


DROP PROCEDURE IF EXISTS kw_set_evaluation_type;

CREATE PROCEDURE kw_set_evaluation_type
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_evaluation_type		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET EvaluationType = vr_evaluation_type
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_evaluators;

CREATE PROCEDURE kw_set_evaluators
	vr_application_id			UUID,
	vr_knowledge_type_id		UUID,
	vr_evaluators				varchar(20),
	vr_min_evaluations_count INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET Evaluators = vr_evaluators,
			MinEvaluationsCount = vr_min_evaluations_count
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_pre_evaluate_by_owner;

CREATE PROCEDURE kw_set_pre_evaluate_by_owner
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET PreEvaluateByOwner = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_force_evaluators_describe;

CREATE PROCEDURE kw_set_force_evaluators_describe
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET ForceEvaluatorsDescribe = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_node_select_type;

CREATE PROCEDURE kw_set_node_select_type
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_nodeSelectType		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET NodeSelectType = vr_nodeSelectType
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_searchability_type;

CREATE PROCEDURE kw_set_searchability_type
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_searchableAfter	varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET SearchableAfter = vr_searchableAfter
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_score_scale;

CREATE PROCEDURE kw_set_score_scale
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_scoreScale		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET ScoreScale = vr_scoreScale
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_min_acceptable_score;

CREATE PROCEDURE kw_set_min_acceptable_score
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_min_acceptable_score	float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET MinAcceptableScore = vr_min_acceptable_score
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_evaluations_editable;

CREATE PROCEDURE kw_set_evaluations_editable
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET EvaluationsEditable = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_evaluations_editable_for_admin;

CREATE PROCEDURE kw_set_evaluations_editable_for_admin
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET EvaluationsEditableForAdmin = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_evaluations_removable;

CREATE PROCEDURE kw_set_evaluations_removable
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET EvaluationsRemovable = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_unhide_evaluators;

CREATE PROCEDURE kw_set_unhide_evaluators
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET UnhideEvaluators = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_unhide_evaluations;

CREATE PROCEDURE kw_set_unhide_evaluations
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET UnhideEvaluations = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_unhide_node_creators;

CREATE PROCEDURE kw_set_unhide_node_creators
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET UnhideNodeCreators = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_text_options;

CREATE PROCEDURE kw_set_text_options
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value			 VARCHAR(max)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET TextOptions = vr_value
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_convert_evaluators_to_experts;

CREATE PROCEDURE kw_set_convert_evaluators_to_experts
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_value			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_knowledge_types
		SET ConvertEvaluatorsToExperts = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_candidate_relations;

CREATE PROCEDURE kw_set_candidate_relations
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_strNodeTypeIDs		varchar(max),
	vr_strNodeIDs			varchar(max),
	vr_delimiter			char,
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_iDs Table(NodeTypeID UUID, NodeID UUID)
	
	INSERT INTO vr_iDs (NodeTypeID)
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_iDs (NodeID)
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_existingIDs Table(NodeTypeID UUID, NodeID UUID)
	
	INSERT INTO vr_existingIDs(NodeTypeID, NodeID)
	SELECT cr.node_type_id, cr.node_id
	FROM vr_iDs AS ref
		INNER JOIN kw_candidate_relations AS cr
		ON cr.node_type_id = ref.node_type_id OR cr.node_id = ref.node_id
	WHERE cr.application_id = vr_application_id AND cr.knowledge_type_id = vr_knowledge_type_id
	
	DECLARE vr_count INTEGER = (SELECT COUNT(*) FROM vr_iDs)
	DECLARE vr_existingCount INTEGER = (SELECT COUNT(*) FROM vr_existingIDs)
	
	IF EXISTS(SELECT * FROM kw_candidate_relations
		WHERE KnowledgeTypeID = vr_knowledge_type_id) BEGIN
		
		UPDATE kw_candidate_relations
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = TRUE
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr_existingCount > 0 BEGIN
		UPDATE CR
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		FROM vr_existingIDs AS ref
			INNER JOIN kw_candidate_relations AS cr
			ON cr.node_type_id = ref.node_type_id OR cr.node_id = ref.node_id
		WHERE cr.application_id = vr_application_id AND cr.knowledge_type_id = vr_knowledge_type_id
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr_count > vr_existingCount BEGIN
		INSERT INTO kw_candidate_relations(
			ApplicationID,
			ID,
			KnowledgeTypeID,
			NodeID,
			NodeTypeID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT vr_application_id, gen_random_uuid(), vr_knowledge_type_id, ref.node_id, ref.node_type_id, 
			vr_creator_user_id, vr_creation_date, 0
		FROM (
				SELECT i.*
				FROM vr_iDs AS i
					LEFT JOIN vr_existingIDs AS e
					ON i.node_id = e.node_id OR i.node_type_id = e.node_type_id
				WHERE e.node_id IS NULL AND e.node_type_id IS NULL
			) AS ref
		
		IF @vr_rowcount <= 0 BEGIN
		select 6
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_get_candidate_node_relation_ids;

CREATE PROCEDURE kw_get_candidate_node_relation_ids
	vr_application_id					UUID,
	vr_knowledge_type_idOrKnowledgeID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_knowledge_type_idOrKnowledgeID = COALESCE(
		(
			SELECT TOP(1) NodeTypeID
			FROM cn_nodes
			WHERE ApplicationID = vr_application_id AND NodeID = vr_knowledge_type_idOrKnowledgeID
		), vr_knowledge_type_idOrKnowledgeID
	)
	
	SELECT NodeID AS id
	FROM kw_candidate_relations
	WHERE ApplicationID = vr_application_id AND 
		KnowledgeTypeID = vr_knowledge_type_idOrKnowledgeID AND 
		NodeID IS NOT NULL AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS kw_get_candidate_node_type_relation_ids;

CREATE PROCEDURE kw_get_candidate_node_type_relation_ids
	vr_application_id					UUID,
	vr_knowledge_type_idOrKnowledgeID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_knowledge_type_idOrKnowledgeID = COALESCE(
		(
			SELECT TOP(1) NodeTypeID
			FROM cn_nodes
			WHERE ApplicationID = vr_application_id AND NodeID = vr_knowledge_type_idOrKnowledgeID
		), vr_knowledge_type_idOrKnowledgeID
	)
	
	SELECT NodeTypeID AS id
	FROM kw_candidate_relations
	WHERE ApplicationID = vr_application_id AND 
		KnowledgeTypeID = vr_knowledge_type_idOrKnowledgeID AND 
		NodeTypeID IS NOT NULL AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS kw_add_question;

CREATE PROCEDURE kw_add_question
	vr_application_id		UUID,
	vr_iD					UUID,
	vr_knowledge_type_id	UUID,
	vr_node_id				UUID,
	vr_question_body	 VARCHAR(2000),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	IF vr_question_body IS NOT NULL SET vr_question_body = gfn_verify_string(vr_question_body)
	
	DECLARE vr_question_id UUID = (
		SELECT QuestionID 
		FROM kw_questions 
		WHERE ApplicationID = vr_application_id AND Title = vr_question_body
	)
	
	IF vr_question_id IS NOT NULL AND EXISTS(
		SELECT TOP(1) *
		FROM kw_type_questions
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id AND
			QuestionID = vr_question_id AND deleted = FALSE
	) BEGIN
		SELECT -1, N'QuestionAlreadyExists'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_question_id IS NULL BEGIN
		SET vr_question_id = gen_random_uuid()
		
		INSERT INTO kw_questions(
			ApplicationID,
			QuestionID,
			Title,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_question_id,
			vr_question_body,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE vr_sequenceNumber INTEGER = (
		SELECT MAX(SequenceNumber) 
		FROM kw_type_questions
		WHERE ApplicationID = vr_application_id AND KnowledgeTypeID = vr_knowledge_type_id
	)
	
	SET vr_sequenceNumber = COALESCE(vr_sequenceNumber, 0) + 1
	
	INSERT INTO kw_type_questions(
		ApplicationID,
		ID,
		KnowledgeTypeID,
		QuestionID,
		NodeID,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_iD,
		vr_knowledge_type_id,
		vr_question_id,
		vr_node_id,
		vr_sequenceNumber,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_modify_question;

CREATE PROCEDURE kw_modify_question
	vr_application_id			UUID,
	vr_iD						UUID,
	vr_question_body		 VARCHAR(2000),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	IF vr_question_body IS NOT NULL SET vr_question_body = gfn_verify_string(vr_question_body)
	
	DECLARE vr_question_id UUID = (
		SELECT TOP(1) QuestionID 
		FROM kw_questions 
		WHERE ApplicationID = vr_application_id AND Title = vr_question_body AND deleted = FALSE
	)
	
	IF vr_question_id IS NULL BEGIN
		SET vr_question_id = gen_random_uuid()
		
		INSERT INTO kw_questions(
			ApplicationID,
			QuestionID,
			Title,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_question_id,
			vr_question_body,
			vr_last_modifier_user_id,
			vr_last_modification_date,
			0
		)
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	UPDATE kw_type_questions
		SET QuestionID = vr_question_id,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_set_questions_order;

CREATE PROCEDURE kw_set_questions_order
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs TABLE (SequenceNo INTEGER identity(1, 1) primary key, ID UUID)
	
	INSERT INTO vr_iDs (ID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
	
	DECLARE vr_knowledge_type_id UUID = NULL, vr_node_id UUID = NULL
	
	SELECT vr_knowledge_type_id = KnowledgeTypeID, vr_node_id = NodeID
	FROM kw_type_questions
	WHERE ApplicationID = vr_application_id AND 
		ID = (SELECT TOP (1) ref.id FROM vr_iDs AS ref)
	
	IF vr_knowledge_type_id IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO vr_iDs (ID)
	SELECT tq.id
	FROM vr_iDs AS ref
		RIGHT JOIN kw_type_questions AS tq
		ON tq.id = ref.id
	WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND 
		((vr_node_id IS NULL AND tq.node_id IS NULL) OR tq.node_id = vr_node_id) AND ref.id IS NULL
	ORDER BY tq.sequence_number
	
	UPDATE TQ
		SET SequenceNumber = ref.sequence_no
	FROM vr_iDs AS ref
		INNER JOIN kw_type_questions AS tq
		ON tq.id = ref.id
	WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND 
		((vr_node_id IS NULL AND tq.node_id IS NULL) OR tq.node_id = vr_node_id)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_question_weight;

CREATE PROCEDURE kw_set_question_weight
	vr_application_id	UUID,
	vr_iD				UUID,
	vr_weight			float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_weight <= 0 SET vr_weight = NULL
	
	UPDATE kw_type_questions
		SET weight = vr_weight
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_arithmetic_delete_question;

CREATE PROCEDURE kw_arithmetic_delete_question
	vr_application_id			UUID,
	vr_iD						UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_type_questions
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_arithmetic_delete_related_node_questions;

CREATE PROCEDURE kw_arithmetic_delete_related_node_questions
	vr_application_id			UUID,
	vr_knowledge_type_id		UUID,
	vr_node_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_type_questions
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND 
		KnowledgeTypeID = vr_knowledge_type_id AND NodeID = vr_node_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_add_answer_option;

CREATE PROCEDURE kw_add_answer_option
	vr_application_id			UUID,
	vr_iD						UUID,
	vr_typeQuestionID			UUID,
	vr_title				 VARCHAR(2000),
	vr_value					float,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_value IS NULL OR vr_value < 0 OR vr_value > 10 OR EXISTS(
		SELECT TOP(1) ID
		FROM kw_answer_options
		WHERE ApplicationID = vr_application_id AND TypeQuestionID = vr_typeQuestionID AND 
		 deleted = FALSE AND Value = vr_value
	) BEGIN
		SELECT -1, N'AnswerOptionValueIsNotValid'
		RETURN
	END
	
	DECLARE vr_seqNo INTEGER = COALESCE(
		(
			SELECT MAX(SequenceNumber)
			FROM kw_answer_options
			WHERE ApplicationID = vr_application_id AND 
				TypeQuestionID = vr_typeQuestionID AND deleted = FALSE
		), 0) + 1
	
	INSERT INTO kw_answer_options (
		ApplicationID,
		ID,
		TypeQuestionID,
		Title,
		Value,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		vr_application_id,
		vr_iD,
		vr_typeQuestionID,
		vr_title,
		vr_value,
		vr_seqNo,
		vr_current_user_id,
		vr_now,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_modify_answer_option;

CREATE PROCEDURE kw_modify_answer_option
	vr_application_id			UUID,
	vr_iD						UUID,
	vr_title				 VARCHAR(2000),
	vr_value					float,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_typeQuestionID UUID = (
		SELECT TOP(1) TypeQuestionID
		FROM kw_answer_options
		WHERE ApplicationID = vr_application_id AND ID = vr_iD
	)
	
	IF vr_value IS NULL OR vr_value < 0 OR vr_value > 10 OR EXISTS(
		SELECT TOP(1) ID
		FROM kw_answer_options
		WHERE ApplicationID = vr_application_id AND TypeQuestionID = vr_typeQuestionID AND 
		 deleted = FALSE AND ID <> vr_iD AND Value = vr_value
	) BEGIN
		SELECT -1, N'AnswerOptionValueIsNotValid'
		RETURN
	END
	
	UPDATE kw_answer_options
		SET Title = vr_title,
			Value = vr_value,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_set_answer_options_order;

CREATE PROCEDURE kw_set_answer_options_order
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs TABLE (SequenceNo INTEGER identity(1, 1) primary key, ID UUID)
	
	INSERT INTO vr_iDs (ID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
	
	DECLARE vr_question_id UUID
	
	SELECT vr_question_id = TypeQuestionID
	FROM kw_answer_options
	WHERE ApplicationID = vr_application_id AND 
		ID = (SELECT TOP (1) ref.id FROM vr_iDs AS ref)
	
	IF vr_question_id IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO vr_iDs (ID)
	SELECT ao.id
	FROM vr_iDs AS ref
		RIGHT JOIN kw_answer_options AS ao
		ON ao.id = ref.id
	WHERE ao.application_id = vr_application_id AND ao.type_question_id = vr_question_id AND ref.id IS NULL
	ORDER BY ao.sequence_number
	
	UPDATE AO
		SET SequenceNumber = ref.sequence_no
	FROM vr_iDs AS ref
		INNER JOIN kw_answer_options AS ao
		ON ao.id = ref.id
	WHERE ao.application_id = vr_application_id AND ao.type_question_id = vr_question_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_arithmetic_delete_answer_option;

CREATE PROCEDURE kw_arithmetic_delete_answer_option
	vr_application_id			UUID,
	vr_iD						UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_answer_options
		SET LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_get_questions;

CREATE PROCEDURE kw_get_questions
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	tq.id, 
			tq.knowledge_type_id, 
			tq.question_id, 
			q.title AS question_body,
			nd.node_id AS related_node_id,
			nd.name AS related_node_name,
			tq.weight
	FROM kw_type_questions AS tq
		INNER JOIN kw_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = Tq.question_id
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = tq.node_id
	WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND 
		(nd.node_id IS NULL OR nd.deleted = FALSE) AND tq.deleted = FALSE
	ORDER BY tq.sequence_number
END;


DROP PROCEDURE IF EXISTS kw_search_questions;

CREATE PROCEDURE kw_search_questions
	vr_application_id		UUID,
	vr_searchText		 VARCHAR(1000),
	vr_count			 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_verify_string(vr_searchText)
	
	DECLARE vr__st VARCHAR(1000) = vr_searchText
	IF vr_searchText IS NULL OR vr_searchText = N'' SET vr__st = NULL
	
	IF vr_count IS NULL OR vr_count <= 0 SET vr_count = 1000000000
	
	IF vr__st IS NULL BEGIN
		SELECT TOP(vr_count) Title AS value
		FROM kw_questions
		WHERE ApplicationID = vr_application_id AND deleted = FALSE
	END
	ELSE BEGIN
		SELECT TOP(vr_count) Title AS value
		FROM CONTAINSTABLE(kw_questions, title, vr__st) AS srch
			INNER JOIN kw_questions AS q
			ON q.question_id = srch.key
		WHERE q.application_id = vr_application_id AND deleted = FALSE
		ORDER BY srch.rank DESC
	END
END;


DROP PROCEDURE IF EXISTS kw_get_answer_options;

CREATE PROCEDURE kw_get_answer_options
	vr_application_id		UUID,
	vr_strTypeQuestionIDs	varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_typeQuestionIDs GuidTableType
	
	INSERT INTO vr_typeQuestionIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strTypeQuestionIDs, vr_delimiter) AS ref
	
	SELECT	ao.id,
			ao.type_question_id, 
			ao.title,
			ao.value
	FROM vr_typeQuestionIDs AS i_ds
		INNER JOIN kw_type_questions AS tq
		ON tq.application_id = vr_application_id AND tq.id = i_ds.value
		INNER JOIN kw_answer_options AS ao
		ON ao.application_id = vr_application_id AND ao.type_question_id = tq.id
	WHERE tq.deleted = FALSE AND ao.deleted = FALSE
	ORDER BY ao.type_question_id ASC, ao.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS kw_get_filled_evaluation_form;

CREATE PROCEDURE kw_get_filled_evaluation_form
	vr_application_id		UUID,
    vr_knowledge_id		UUID,
    vr_user_id				UUID,
    vr_wf_version_id	 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_scoreScale INTEGER = (
		SELECT TOP(1) ScoreScale
		FROM cn_nodes AS nd
			INNER JOIN kw_knowledge_types AS kt
			ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id
	)
	
	DECLARE vr_coeff float = CAST(COALESCE(vr_scoreScale, 10) AS float) / 10.0
	
	DECLARE vr_last_wf_version_id INTEGER = kw_fn_get_wf_version_id(vr_application_id, vr_knowledge_id)
	
	IF vr_wf_version_id IS NULL OR vr_wf_version_id = vr_last_wf_version_id BEGIN
		SELECT	qa.question_id,
				qa.title,
				o.title AS text_value,
				COALESCE(qa.admin_score, qa.score) * vr_coeff AS score,
				qa.evaluation_date
		FROM kw_question_answers AS qa
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = qa.knowledge_id
			LEFT JOIN kw_answer_options AS o
			ON o.application_id = vr_application_id AND o.id = qa.selected_option_id
			LEFT JOIN kw_type_questions AS q
			ON q.application_id = vr_application_id AND 
				q.knowledge_type_id = nd.node_type_id AND q.question_id = qa.question_id
		WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_knowledge_id AND 
			qa.user_id = vr_user_id AND qa.deleted = FALSE
		ORDER BY q.sequence_number ASC
	END
	ELSE BEGIN
		SELECT	qa.question_id,
				qa.title,
				o.title AS text_value,
				COALESCE(qa.admin_score, qa.score) * vr_coeff AS score,
				qa.evaluation_date
		FROM kw_question_answers_history AS qa
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = qa.knowledge_id
			LEFT JOIN kw_answer_options AS o
			ON o.application_id = vr_application_id AND o.id = qa.selected_option_id
			LEFT JOIN kw_type_questions AS q
			ON q.application_id = vr_application_id AND 
				q.knowledge_type_id = nd.node_type_id AND q.question_id = qa.question_id
		WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_knowledge_id AND 
			qa.user_id = vr_user_id AND qa.deleted = FALSE AND qa.wf_version_id = vr_wf_version_id
		ORDER BY q.sequence_number ASC
	END
END;


DROP PROCEDURE IF EXISTS kw_p_calculate_knowledge_score;

CREATE PROCEDURE kw_p_calculate_knowledge_score
	vr_application_id		UUID,
    vr_knowledge_id		UUID,
    vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_date_from TIMESTAMP = (
		SELECT TOP(1) MIN(h.action_date)
		FROM kw_history AS h
		WHERE h.application_id = vr_application_id AND
			h.knowledge_id = vr_knowledge_id AND h.action = N'SendToAdmin'
	)
	
	DECLARE vr_score float = 0
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM kw_question_answers AS qa
			LEFT JOIN cn_nodes AS nd
			INNER JOIN kw_type_questions AS tq
			ON tq.application_id = vr_application_id AND 
				tq.knowledge_type_id = nd.node_type_id AND tq.deleted = FALSE
			ON nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id AND
				nd.node_id = qa.knowledge_id
		WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_knowledge_id AND 
			qa.deleted = FALSE AND (tq.weight IS NULL OR tq.weight <= 0)
	) BEGIN
		SELECT TOP(1) vr_score = (SUM(ref.score) / COALESCE(COUNT(ref.user_id), 1))
		FROM (
				SELECT	qa.user_id, 
						SUM(COALESCE(COALESCE(qa.admin_score, qa.score), 0)) / COALESCE(COUNT(qa.question_id), 1) AS score
				FROM kw_question_answers AS qa
				WHERE qa.application_id = vr_application_id AND 
					qa.knowledge_id = vr_knowledge_id AND qa.deleted = FALSE AND
					(vr_date_from IS NULL OR qa.evaluation_date > vr_date_from)
				GROUP BY qa.user_id
			) AS ref
	END
	ELSE BEGIN
		SELECT TOP(1) vr_score = (SUM(ref.score) / COALESCE(COUNT(ref.user_id), 1))
		FROM (
				SELECT	qa.user_id,
						SUM((tq.weight * COALESCE(COALESCE(qa.admin_score, qa.score), 0))) / SUM(tq.weight) AS score
				FROM kw_question_answers AS qa
					INNER JOIN cn_nodes AS nd
					INNER JOIN kw_type_questions AS tq
					ON tq.application_id = vr_application_id AND 
						tq.knowledge_type_id = nd.node_type_id AND tq.deleted = FALSE
					ON nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id AND
						nd.node_id = qa.knowledge_id
				WHERE qa.application_id = vr_application_id AND 
					qa.knowledge_id = vr_knowledge_id AND qa.deleted = FALSE AND
					(vr_date_from IS NULL OR qa.evaluation_date > vr_date_from)
				GROUP BY qa.user_id
			) AS ref
	END
	
	UPDATE cn_nodes
		SET Score = vr_score
	WHERE ApplicationID = vr_application_id AND NodeID = vr_knowledge_id
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_get_evaluations_done;

CREATE PROCEDURE kw_get_evaluations_done
	vr_application_id		UUID,
    vr_knowledge_id		UUID,
    vr_wf_version_id	 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_date_from TIMESTAMP = (
		SELECT TOP(1) MIN(h.action_date)
		FROM kw_history AS h
		WHERE h.application_id = vr_application_id AND
			h.knowledge_id = vr_knowledge_id AND h.action = N'SendToAdmin'
	)
	
	DECLARE vr_last_version_id INTEGER = kw_fn_get_wf_version_id(vr_application_id, vr_knowledge_id)
	
	SELECT *
	FROM (
			SELECT	ref.user_id,
					un.username,
					un.first_name,
					un.last_name,
					ref.score,
					ref.evaluation_date,
					vr_last_version_id AS wf_version_id
			FROM (
					SELECT a.user_id, (SUM(COALESCE(COALESCE(a.admin_score, a.score), 0)) / COALESCE(COUNT(a.user_id), 1)) AS score,
						MAX(a.evaluation_date) AS evaluation_date
					FROM kw_question_answers AS a
					WHERE a.application_id = vr_application_id AND 
						a.knowledge_id = vr_knowledge_id AND a.deleted = FALSE AND
						(vr_date_from IS NULL OR a.evaluation_date > vr_date_from)
					GROUP BY a.user_id
				) AS ref
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.user_id
			WHERE vr_wf_version_id IS NULL OR vr_last_version_id = vr_wf_version_id
	
			UNION ALL
	
			SELECT	ref.user_id,
					un.username,
					un.first_name,
					un.last_name,
					ref.score,
					ref.evaluation_date,
					ref.wf_version_id
			FROM (
					SELECT a.user_id, (SUM(COALESCE(COALESCE(a.admin_score, a.score), 0)) / COALESCE(COUNT(a.user_id), 1)) AS score,
						MAX(a.evaluation_date) AS evaluation_date, a.wf_version_id
					FROM kw_question_answers_history AS a
					WHERE a.application_id = vr_application_id AND 
						a.knowledge_id = vr_knowledge_id AND a.deleted = FALSE AND
						(vr_date_from IS NULL OR a.evaluation_date > vr_date_from) AND
						(vr_wf_version_id IS NULL OR a.wf_version_id = vr_wf_version_id)
					GROUP BY a.user_id, a.wf_version_id
				) AS ref
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.user_id
		) AS x
	ORDER BY x.wf_version_id DESC, x.evaluation_date DESC
END;


DROP PROCEDURE IF EXISTS kw_has_evaluated;

CREATE PROCEDURE kw_has_evaluated
	vr_application_id	UUID,
    vr_knowledge_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) CAST(1 AS boolean)
	FROM kw_question_answers AS a
	WHERE a.application_id = vr_application_id AND a.knowledge_id = vr_knowledge_id AND 
		a.user_id = vr_user_id AND a.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS kw_p_auto_set_knowledge_status;

CREATE PROCEDURE kw_p_auto_set_knowledge_status
	vr_application_id				UUID,
    vr_node_id						UUID,
    vr_now					 TIMESTAMP,
    vr__searchability_activated BOOLEAN output,
    vr__accepted				 BOOLEAN output,
    vr__result				 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr__searchability_activated = 0
	SET vr__accepted = 0
	
	DECLARE vr_evaluatorsCount INTEGER, vr_cur_evaluators_count INTEGER, vr_min_evaluators_count INTEGER
	
	EXEC ntfn_p_get_dashboards_count vr_application_id, NULL, vr_node_id, NULL, 
		N'Knowledge', N'Evaluator', vr_evaluatorsCount output
	
	SELECT TOP(1) vr_min_evaluators_count = kt.min_evaluations_count
	FROM cn_nodes AS nd
		INNER JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	
	SET vr_cur_evaluators_count = COALESCE(
		(
			SELECT TOP(1) COUNT(DISTINCT UserID)
			FROM kw_question_answers AS qa
			WHERE qa.application_id = vr_application_id AND 
				qa.knowledge_id = vr_node_id AND qa.deleted = FALSE
			GROUP BY qa.user_id
		), 0
	)
	
	IF vr_min_evaluators_count IS NULL OR vr_min_evaluators_count <= 0 OR 
		vr_min_evaluators_count > (vr_evaluatorsCount + vr_cur_evaluators_count) 
		SET vr_min_evaluators_count = vr_evaluatorsCount + vr_cur_evaluators_count
	
	IF vr_cur_evaluators_count >= vr_min_evaluators_count BEGIN
		EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
			NULL, vr_node_id, NULL, N'Knowledge', NULL, vr__result output
			
		IF vr__result <= 0 RETURN
	
		DECLARE vr_st varchar(50), vr_sc float
		
		SELECT TOP(1) vr_st = nd.status, vr_sc = nd.score
		FROM cn_nodes AS nd 
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		
		DECLARE vr_acceptable BOOLEAN = (
			SELECT TOP(1) 
				CASE
					WHEN COALESCE(vr_sc, 0) >= (
							(COALESCE(kt.min_acceptable_score, 0) * 10) / 
							COALESCE(CASE WHEN kt.score_scale = 0 THEN 1 ELSE kt.score_scale END, 1)
						) THEN CAST(1 AS boolean)
					ELSE CAST(0 AS boolean)
				END
			FROM cn_nodes AS nd
				INNER JOIN kw_knowledge_types AS kt
				ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		)
		
		IF (vr_acceptable = 1 AND vr_st <> N'Accepted') OR 
			(COALESCE(vr_acceptable, 0) = 0 AND vr_st <> N'Rejected') BEGIN
			UPDATE cn_nodes
				SET status = CASE WHEN vr_acceptable = 1 THEN N'Accepted' ELSE N'Rejected' END,
					publication_date = vr_now
			WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
			
			IF vr_acceptable = 1 SET vr__accepted = 1
		END
		
		DECLARE vr_isSearchable BOOLEAN = (
			SELECT TOP(1) nd.searchable
			FROM cn_nodes AS nd 
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		)
		
		IF COALESCE(vr_isSearchable, 0) = 0 AND vr__accepted = 1 BEGIN
			UPDATE cn_nodes
				SET searchable = TRUE
			WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
			
			-- Set searchability of previous version
			/*
			DECLARE vr_previous_version_id UUID = (
				SELECT TOP(1) PreviousVersionID
				FROM cn_nodes
				WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
			)
			
			IF vr_previous_version_id IS NOT NULL BEGIN
				UPDATE cn_nodes
					SET searchable = FALSE
				WHERE ApplicationID = vr_application_id AND NodeID = vr_previous_version_id
			END
			*/
			-- end of Set searchability of previous version
			
			SET vr__searchability_activated = 1
		END
	END
END;


DROP PROCEDURE IF EXISTS kw_p_accept_reject_knowledge;

CREATE PROCEDURE kw_p_accept_reject_knowledge
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_accept		 BOOLEAN,
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_searchable BOOLEAN = CAST((CASE WHEN vr_accept = 1 THEN 1 ELSE 0 END) AS boolean)
	
	UPDATE cn_nodes
		SET status = CASE WHEN vr_accept = 1 THEN N'Accepted' ELSE N'Rejected' END,
			searchable = vr_searchable
	WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	
	IF @vr_rowcount <= 0 BEGIN
		SET vr__result = -1
		RETURN
	END
	
	IF vr_searchable = 1 BEGIN
		DECLARE vr_previous_version_id UUID = (
			SELECT TOP(1) PreviousVersionID
			FROM cn_nodes
			WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
		)
		
		IF vr_previous_version_id IS NOT NULL BEGIN
			UPDATE cn_nodes
				SET searchable = FALSE
			WHERE ApplicationID = vr_application_id AND NodeID = vr_previous_version_id
		END
	END
	
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, vr_node_id, NULL, N'Knowledge', NULL, vr__result output
END;


DROP PROCEDURE IF EXISTS kw_accept_reject_knowledge;

CREATE PROCEDURE kw_accept_reject_knowledge
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
    vr_accept		 BOOLEAN,
    vr_textOptions VARCHAR(1000),
    vr_description VARCHAR(2000),
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC kw_p_accept_reject_knowledge vr_application_id, vr_node_id, vr_accept, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT vr__result
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		TextOptions,
		description,
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		CASE WHEN COALESCE(vr_accept, 0) = 1 THEN N'Accept' ELSE N'Reject' END,
		vr_textOptions,
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_send_to_admin;

CREATE PROCEDURE kw_send_to_admin
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_current_user_id		UUID,
    vr_strAdminUserIDs	varchar(max),
    vr_delimiter			char,
    vr_description	 VARCHAR(2000),
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Set knowledge status to 'SentToAdmin'
	-- 2: Create history
	-- 3: Send old evaluations to history
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	-- Find AdminIDs
	DECLARE vr_adminUserIDs GuidTableType
	
	INSERT INTO vr_adminUserIDs
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strAdminUserIDs, vr_delimiter) AS ref
	-- end of Find AdminIDs
	
	
	-- Check if is new workflow
	DECLARE vr_isNewVersion BOOLEAN = 0
	
	IF EXISTS(
		SELECT TOP(1) nd.node_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id AND nd.status = N'Rejected'
	) SET vr_isNewVersion = 1
	
	DECLARE vr_wf_version_id INTEGER = kw_fn_get_wf_version_id(vr_application_id, vr_node_id)
	DECLARE vr_new_wf_version_id INTEGER = vr_wf_version_id + (CASE WHEN vr_isNewVersion = 1 THEN 1 ELSE 0 END)
	-- end of Check if is new workflow
	
	
	-- Set new knowledge status
	UPDATE cn_nodes
		SET status = N'SentToAdmin'
	WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set new knowledge status
	
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		description,
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'SendToAdmin',
		vr_description,
		vr_current_user_id,
		vr_now,
		vr_new_wf_version_id,
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	-- send old evaluations to history
	
	DECLARE vr_version_id UUID = gen_random_uuid()
	
	INSERT INTO kw_question_answers_history (ApplicationID, VersionID, KnowledgeID, UserID, QuestionID,  Title, Score, 
		EvaluationDate, Deleted, SelectedOptionID, VersionDate, AdminScore, AdminSelectedOptionID, AdminID, WFVersionID)
	SELECT a.application_id, vr_version_id, a.knowledge_id, a.user_id, a.question_id, a.title, a.score, 
		a.evaluation_date, a.deleted, a.selected_option_id, vr_now, a.admin_score, a.admin_selected_option_id, a.admin_id, vr_wf_version_id
	FROM kw_question_answers AS a
	WHERE a.application_id = vr_application_id AND a.knowledge_id = vr_node_id
	
	DELETE kw_question_answers
	WHERE ApplicationID = vr_application_id AND KnowledgeID = vr_node_id 
	
	-- end of send old evaluations to history
	
	DECLARE vr__result INTEGER
	
	-- Remove all existing dashboards
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, vr_node_id, NULL, NULL, NULL, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	DECLARE vr_dashboards DashboardTableType
	
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate, Info)
	SELECT	ref.value, 
			vr_node_id,
			vr_node_id,
			N'Knowledge',
			N'Admin',
			0,
			vr_now,
			N'{"WFVersionID":' + CAST(vr_new_wf_version_id AS varchar(50)) + N'}'
	FROM vr_adminUserIDs AS ref
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	ELSE BEGIN
		SELECT * 
		FROM vr_dashboards
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_send_back_for_revision;

CREATE PROCEDURE kw_send_back_for_revision
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_current_user_id		UUID,
    vr_textOptions	 VARCHAR(1000),
    vr_description	 VARCHAR(2000),
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Set knowledge status to 'SentBackForRevision'
	-- 2: Create history
	-- 3: Set current user's admin dashboard AS done
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	-- Set new knowledge status
	UPDATE cn_nodes
		SET status = N'SentBackForRevision'
	WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set new knowledge status
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		TextOptions,
		description,
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'SendBackForRevision',
		vr_textOptions,
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE vr__result INTEGER
	
	-- Set dashboards AS done
	EXEC ntfn_p_set_dashboards_as_done vr_application_id,
		vr_current_user_id, vr_node_id, NULL, N'Knowledge', N'Admin', vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set dashboards AS done
	
	-- Remove all existing dashboards
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, vr_node_id, NULL, NULL, NULL, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	DECLARE vr_dashboards DashboardTableType
	
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate)
	SELECT	nd.creator_user_id,
			vr_node_id,
			vr_node_id,
			N'Knowledge',
			N'Revision',
			1,
			vr_now
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	ELSE BEGIN
		SELECT * 
		FROM vr_dashboards
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_p_new_evaluators;

CREATE PROCEDURE kw_p_new_evaluators
	vr_application_id			UUID,
    vr_node_id					UUID,
    vr_evaluator_user_ids_temp	GuidTableType readonly,
    vr_now				 TIMESTAMP,
    vr__result			 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_evaluator_user_ids GuidTableType
	INSERT INTO vr_evaluator_user_ids SELECT * FROM vr_evaluator_user_ids_temp
	
	/* Steps: */
	-- 1: Send new dashboards to admins
	
	-- Send new dashboards
	DECLARE vr_dashboards DashboardTableType
	
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate)
	SELECT	ev.value,
			vr_node_id,
			vr_node_id,
			N'Knowledge',
			N'Evaluator',
			0,
			vr_now
	FROM vr_evaluator_user_ids AS ev
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result > 0 BEGIN
		SELECT * 
		FROM vr_dashboards
	END
	-- end of send new dashboards
END;


DROP PROCEDURE IF EXISTS kw_new_evaluators;

CREATE PROCEDURE kw_new_evaluators
	vr_application_id			UUID,
    vr_node_id					UUID,
    vr_strEvaluatorUserIDs	varchar(max),
    vr_delimiter				char,
    vr_now				 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Send new dashboards to admins
	
	DECLARE vr_evaluator_user_ids GuidTableType
	
	INSERT INTO vr_evaluator_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strEvaluatorUserIDs, vr_delimiter) AS ref
	
	DECLARE vr__result INTEGER
	
	-- Send new dashboards
	EXEC kw_p_new_evaluators vr_application_id, 
		vr_node_id, vr_evaluator_user_ids, vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_send_to_evaluators;

CREATE PROCEDURE kw_send_to_evaluators
	vr_application_id			UUID,
    vr_node_id					UUID,
    vr_current_user_id			UUID,
    vr_strEvaluatorUserIDs	varchar(max),
    vr_delimiter				char,
    vr_description		 VARCHAR(2000),
    vr_now				 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Set knowledge status to 'SentToEvaluators'
	-- 2: Create History
	-- 3: Set current user's admin dashboard AS done
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	DECLARE vr_evaluator_user_ids GuidTableType
	
	INSERT INTO vr_evaluator_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strEvaluatorUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_searchableAfter varchar(50) = (
		SELECT kt.searchable_after
		FROM cn_nodes AS nd
			INNER JOIN kw_knowledge_types AS kt
			ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	)
	
	-- Set new knowledge status
	DECLARE vr_searchabilityStatus BOOLEAN = COALESCE((
		SELECT TOP(1) Searchable
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	), 1)
	
	DECLARE vr_searchable BOOLEAN = CAST((
		CASE 
			WHEN vr_searchableAfter = N'Confirmation' THEN 1 
			ELSE vr_searchabilityStatus 
		END
	) AS boolean)
	
	UPDATE cn_nodes
		SET status = N'SentToEvaluators',
			Searchable = CASE WHEN vr_searchableAfter = N'Confirmation' THEN 1 ELSE Searchable END
	WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set new knowledge status
	
	-- Set searchability of previous version
	IF vr_searchabilityStatus = 0 AND vr_searchable = 1 BEGIN
		DECLARE vr_previous_version_id UUID = (
			SELECT TOP(1) PreviousVersionID
			FROM cn_nodes
			WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
		)
		
		IF vr_previous_version_id IS NOT NULL BEGIN
			UPDATE cn_nodes
				SET searchable = FALSE
			WHERE ApplicationID = vr_application_id AND NodeID = vr_previous_version_id
		END
	END
	-- end of Set searchability of previous version
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		description,
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'SendToEvaluators',
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE vr__result INTEGER
	
	-- Set dashboards AS done
	EXEC ntfn_p_set_dashboards_as_done vr_application_id,
		vr_current_user_id, vr_node_id, NULL, N'Knowledge', N'Admin', vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set dashboards AS done
	
	-- Remove all existing dashboards
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, vr_node_id, NULL, NULL, NULL, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	EXEC kw_p_new_evaluators vr_application_id, 
		vr_node_id, vr_evaluator_user_ids, vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_send_knowledge_comment;

CREATE PROCEDURE kw_send_knowledge_comment
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_user_id				UUID,
    vr_reply_to_history_id	bigint,
    vr_strAudienceUserIDs	varchar(max),
    vr_delimiter			char,
    vr_description	 VARCHAR(2000),
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_audienceUserIDs GuidTableType
	
	INSERT INTO vr_audienceUserIDs (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strAudienceUserIDs, vr_delimiter) AS ref
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		ActorUserID,
		ActionDate,
		description,
		ReplyToHistoryID,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'Comment',
		vr_user_id,
		vr_now,
		gfn_verify_string(vr_description),
		vr_reply_to_history_id,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE vr__result INTEGER = 0
	
	DECLARE vr_dashboards DashboardTableType
	
	-- Send new dashboards
	
	DECLARE vr_creator_user_id UUID = (
		SELECT TOP(1) nd.creator_user_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	)
	
	DECLARE vr_username VARCHAR(1000), vr_first_name VARCHAR(1000), vr_last_name VARCHAR(1000)
	
	SELECT TOP(1) vr_username = UserName, vr_first_name = FirstName, vr_last_name = LastName
	FROM users_normal
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id
	
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate, Info)
	SELECT	a.value,
			vr_node_id,
			vr_node_id,
			N'Knowledge',
			N'KnowledgeComment',
			1,
			vr_now,
			N'{"UserID":"' + CAST(vr_user_id AS varchar(50)) + N'"' +
				N',"UserName":"' + gfn_base64_encode(vr_username) + N'"' +
				N',"FirstName":"' + gfn_base64_encode(vr_first_name) + N'"' +
				N',"LastName":"' + gfn_base64_encode(vr_last_name) + N'"' +
			N'}'
	FROM vr_audienceUserIDs AS a
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- end of send new dashboards
	
	SELECT * 
	FROM vr_dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_save_evaluation_form;

CREATE PROCEDURE kw_save_evaluation_form
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_user_id				UUID,
    vr_current_user_id		UUID,
    vr_answersTemp		GuidFloatTableType readonly,
    vr_score				float,
    vr_evaluation_date	 TIMESTAMP,
    vr_adminUserIDsTemp	GuidTableType readonly,
    vr_textOptions	 VARCHAR(1000),
    vr_description	 VARCHAR(2000)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_answers GuidFloatTableType
	INSERT INTO vr_answers SELECT * FROM vr_answersTemp
	
	DECLARE vr_adminUserIDs GuidTableType
	INSERT INTO vr_adminUserIDs SELECT * FROM vr_adminUserIDsTemp
	
	DECLARE vr_ans Table(QuestionID UUID primary key clustered,
		Score float, exists BOOLEAN)
		
	INSERT INTO vr_ans (QuestionID, Score, exists)
	SELECT ref.first_value, ref.second_value, CASE WHEN qa.knowledge_id IS NULL THEN 0 ELSE 1 END
	FROM vr_answers AS ref
		LEFT JOIN kw_question_answers AS qa
		ON qa.application_id = vr_application_id AND qa.knowledge_id = vr_node_id AND 
			qa.user_id = vr_user_id AND qa.question_id = ref.first_value
			
	DECLARE vr_count INTEGER = (SELECT COUNT(*) FROM vr_ans)
	DECLARE vr_existingCount INTEGER = (SELECT COUNT(*) FROM vr_ans WHERE exists = TRUE)
	
	DECLARE vr_devoluted BOOLEAN = 0
	
	IF vr_current_user_id IS NOT NULL AND vr_user_id IS NOT NULL AND vr_current_user_id <> vr_user_id SET vr_devoluted = 1
	
	IF vr_existingCount > 0 BEGIN
		UPDATE QA
			SET Title = q.title,
				Score = CASE WHEN vr_devoluted = 1 THEN qa.score ELSE ref.score END,
				--SelectedOptionID = CASE WHEN vr_devoluted = 1 THEN qa.selected_option_id ELSE ref.selected_option_id END,
				AdminID = CASE WHEN vr_devoluted = 1 THEN vr_current_user_id ELSE NULL END,
				AdminScore = CASE WHEN vr_devoluted = 1 THEN ref.score ELSE qa.admin_score END,
				EvaluationDate = vr_evaluation_date,
			 deleted = FALSE
		FROM vr_ans AS ref
			INNER JOIN kw_question_answers AS qa
			ON qa.question_id = ref.question_id
			INNER JOIN kw_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = ref.question_id
		WHERE qa.application_id = vr_application_id AND ref.exists = TRUE AND 
			qa.knowledge_id = vr_node_id AND qa.user_id = vr_user_id
			
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1, N'SavingEvaluationFormFailed'
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr_count > vr_existingCount BEGIN
		INSERT INTO kw_question_answers(
			ApplicationID,
			KnowledgeID,
			UserID,
			QuestionID,
			Title,
			Score,
			AdminID,
			AdminScore,
			EvaluationDate,
			Deleted
		)
		SELECT	vr_application_id,
				vr_node_id, 
				vr_user_id, 
				ref.question_id, 
				q.title, 
				ref.score,
				CASE WHEN vr_devoluted = 1 THEN vr_current_user_id ELSE NULL END,
				CASE WHEN vr_devoluted = 1 THEN ref.score ELSE NULL END,
				vr_evaluation_date,
				0
		FROM vr_ans AS ref
			INNER JOIN kw_questions AS q
			ON q.question_id = ref.question_id
		WHERE q.application_id = vr_application_id AND COALESCE(ref.exists, FALSE) = 0
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1, N'SavingEvaluationFormFailed'
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		ActorUserID,
		ActionDate,
		DeputyUserID,
		TextOptions,
		description,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'Evaluation',
		vr_user_id,
		vr_evaluation_date,
		CASE WHEN vr_devoluted = 1 THEN vr_current_user_id ELSE NULL END,
		vr_textOptions,
		gfn_verify_string(vr_description),
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE vr__result INTEGER = 0
	
	EXEC kw_p_calculate_knowledge_score vr_application_id, vr_node_id, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'ScoreCalculationFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Set dashboard AS done
	DECLARE vr_uid UUID = COALESCE(vr_user_id, vr_current_user_id)
	
	DECLARE vr_username VARCHAR(1000), vr_first_name VARCHAR(1000), vr_last_name VARCHAR(1000)
	
	SELECT TOP(1) vr_username = UserName, vr_first_name = FirstName, vr_last_name = LastName
	FROM users_normal
	WHERE ApplicationID = vr_application_id AND UserID = vr_uid
	
	EXEC ntfn_p_set_dashboards_as_done vr_application_id, vr_uid, vr_node_id, NULL, 
		N'Knowledge', N'Evaluator', vr_evaluation_date, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set dashboard AS done
	
	
	DECLARE vr__searchability_activated BOOLEAN, vr__accepted BOOLEAN
	
	EXEC kw_p_auto_set_knowledge_status vr_application_id, vr_node_id, vr_evaluation_date, 
		vr__searchability_activated output, vr__accepted output, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'DeterminingKnowledgeStatusFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr_dashboards DashboardTableType
	
	--EXEC ntfn_p_dashboard_exists NULL, vr_node_id, N'Knowledge', 
	--	NULL, NULL, 0, NULL, NULL, vr__result output
	
	-- Send new dashboards
	--IF vr__result > 0 BEGIN
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate, Info)
	SELECT	a.value,
			vr_node_id,
			vr_node_id,
			N'Knowledge',
			N'EvaluationDone',
			1,
			vr_evaluation_date,
			N'{"UserID":"' + CAST(vr_uid AS varchar(50)) + N'"' +
				N',"UserName":"' + gfn_base64_encode(vr_username) + N'"' +
				N',"FirstName":"' + gfn_base64_encode(vr_first_name) + N'"' +
				N',"LastName":"' + gfn_base64_encode(vr_last_name) + N'"' +
			N'}'
	FROM vr_adminUserIDs AS a
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	--END
	-- end of send new dashboards
	
	SELECT * 
	FROM vr_dashboards
	
	DECLARE vr_status varchar(100) = (
		SELECT TOP(1) nd.status
		FROM cn_nodes AS nd 
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	)
	
	SELECT CAST(1 AS integer) AS result, 
		vr__accepted AS accepted, vr__searchability_activated AS searchability_activated, vr_status AS status
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_remove_evaluator;

CREATE PROCEDURE kw_remove_evaluator
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		vr_user_id, vr_node_id, NULL, N'Knowledge', N'Evaluator', vr__result output
		
	UPDATE kw_question_answers
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND KnowledgeID = vr_node_id AND UserID = vr_user_id
	
	SELECT vr__result + @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_refuse_evaluation;

CREATE PROCEDURE kw_refuse_evaluation
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_user_id				UUID,
    vr_now			 TIMESTAMP,
    vr_strAdminUserIDs	varchar(max),
    vr_delimiter			char,
    vr_description	 VARCHAR(2000)
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		ActorUserID,
		ActionDate,
		description,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'RefuseEvaluation',
		vr_user_id,
		vr_now,
		vr_description,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	
	DECLARE vr__result INTEGER
	
	
	-- Remove old dashboards
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		vr_user_id, vr_node_id, NULL, N'Knowledge', N'Evaluator', vr__result output
		
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove old dashboards
	
	
	-- Send new dashboards
	DECLARE vr_adminUserIDs GuidTableType
	INSERT INTO vr_adminUserIDs 
	SELECT ref.value 
	FROM gfn_str_to_guid_table(vr_strAdminUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_username VARCHAR(1000), vr_first_name VARCHAR(1000), vr_last_name VARCHAR(1000)
	SELECT vr_username = UserName, vr_first_name = FirstName, vr_last_name = LastName
	FROM users_normal
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id
	
	DECLARE vr_dashboards DashboardTableType
	
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate, Info)
	SELECT	a.value,
			vr_node_id,
			vr_node_id,
			N'Knowledge',
			N'EvaluationRefused',
			1,
			vr_now,
			N'{"UserID":"' + CAST(vr_user_id AS varchar(50)) + N'"' +
				N',"UserName":"' + gfn_base64_encode(vr_username) + N'"' +
				N',"FirstName":"' + gfn_base64_encode(vr_first_name) + N'"' +
				N',"LastName":"' + gfn_base64_encode(vr_last_name) + N'"' +
			N'}'
	FROM vr_adminUserIDs AS a
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	ELSE BEGIN
		SELECT * 
		FROM vr_dashboards
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_terminate_evaluation;

CREATE PROCEDURE kw_terminate_evaluation
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
    vr_description VARCHAR(2000),
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, vr_node_id, NULL, N'Knowledge', NULL, vr__result output
		
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr__accepted BOOLEAN, vr__searchability_activated BOOLEAN
	
	EXEC kw_p_auto_set_knowledge_status vr_application_id, vr_node_id, vr_now, 
		vr__searchability_activated output, vr__accepted output, vr__result output 
		
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Create history
	INSERT INTO kw_history(
		ApplicationID,
		KnowledgeID,
		action,
		description,
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		N'TerminateEvaluation',
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	SELECT CAST(1 AS integer) AS result, vr__accepted AS accepted, 
		vr__searchability_activated AS searchability_activated
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS kw_get_last_history_version_id;

CREATE PROCEDURE kw_get_last_history_version_id
	vr_application_id	UUID,
    vr_knowledge_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) kw_fn_get_wf_version_id(vr_application_id, vr_knowledge_id) AS value
END;


DROP PROCEDURE IF EXISTS kw_edit_history_description;

CREATE PROCEDURE kw_edit_history_description
	vr_application_id	UUID,
    vr_iD				bigint,
    vr_description VARCHAR(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_history
		SET description = gfn_verify_string(vr_description)
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_get_history;

CREATE PROCEDURE kw_get_history
	vr_application_id	UUID,
    vr_knowledge_id	UUID,
    vr_user_id			UUID,
    vr_action			varchar(50),
    vr_wf_version_id INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	h.id,
			h.knowledge_id,
			h.action,
			h.text_options,
			h.description,
			h.actor_user_id,
			un.username AS actor_username,
			un.first_name AS actor_first_name,
			un.last_name AS actor_last_name,
			h.deputy_user_id,
			dn.username AS deputy_username,
			dn.first_name AS deputy_first_name,
			dn.last_name AS deputy_last_name,
			h.action_date,
			h.reply_to_history_id,
			h.wf_version_id,
			CAST((CASE WHEN nd.creator_user_id = h.actor_user_id THEN 1 ELSE 0 END) AS boolean) AS is_creator,
			CAST((
				SELECT TOP(1) 1
				FROM cn_node_creators AS nc
				WHERE nc.application_id = vr_application_id AND nc.node_id = h.knowledge_id AND 
					nc.user_id = h.actor_user_id AND nc.deleted = FALSE
			) AS boolean) AS is_contributor
	FROM kw_history AS h
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = h.knowledge_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = h.actor_user_id
		LEFT JOIN users_normal AS dn
		ON dn.application_id = vr_application_id AND dn.user_id = h.deputy_user_id
	WHERE h.application_id = vr_application_id AND h.knowledge_id = vr_knowledge_id AND
		(vr_user_id IS NULL OR h.actor_user_id = vr_user_id) AND
		(vr_action IS NULL OR h.action = vr_action) AND
		(vr_wf_version_id IS NULL OR h.wf_version_id = vr_wf_version_id)
	ORDER BY h.id DESC
END;


DROP PROCEDURE IF EXISTS kw_get_history_by_id;

CREATE PROCEDURE kw_get_history_by_id
	vr_application_id	UUID,
    vr_iD				bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	h.id,
			h.knowledge_id,
			h.action,
			h.text_options,
			h.description,
			h.actor_user_id,
			un.username AS actor_username,
			un.first_name AS actor_first_name,
			un.last_name AS actor_last_name,
			h.deputy_user_id,
			dn.username AS deputy_username,
			dn.first_name AS deputy_first_name,
			dn.last_name AS deputy_last_name,
			h.action_date,
			h.reply_to_history_id,
			h.wf_version_id,
			CAST((CASE WHEN nd.creator_user_id = h.actor_user_id THEN 1 ELSE 0 END) AS boolean) AS is_creator,
			CAST((
				SELECT TOP(1) 1
				FROM cn_node_creators AS nc
				WHERE nc.application_id = vr_application_id AND nc.node_id = h.knowledge_id AND 
					nc.user_id = h.actor_user_id AND nc.deleted = FALSE
			) AS boolean) AS is_contributor
	FROM kw_history AS h
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = h.knowledge_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = h.actor_user_id
		LEFT JOIN users_normal AS dn
		ON dn.application_id = vr_application_id AND dn.user_id = h.deputy_user_id
	WHERE h.application_id = vr_application_id AND h.id = vr_iD
END;


/* Knowledge Feedbacks */

DROP PROCEDURE IF EXISTS kw_add_feedback;

CREATE PROCEDURE kw_add_feedback
	vr_application_id	UUID,
	vr_knowledge_id	UUID,
	vr_user_id			UUID,
	vr_feedback_type_id INTEGER,
	vr_sendDate	 TIMESTAMP,
	vr_value			float,
	vr_description VARCHAR(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	IF vr_value IS NULL SET vr_value = 0

	INSERT INTO kw_feedbacks(
		ApplicationID,
		KnowledgeID,
		UserID,
		FeedBackTypeID,
		SendDate,
		Value,
		description,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_knowledge_id,
		vr_user_id,
		vr_feedback_type_id,
		vr_sendDate,
		vr_value,
		vr_description,
		0
	)
	
	SELECT @vr_iDENTITY
END;


DROP PROCEDURE IF EXISTS kw_modify_feedback;

CREATE PROCEDURE kw_modify_feedback
	vr_application_id	UUID,
	vr_feedback_id		bigint,
	vr_value			float,
	vr_description VARCHAR(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE kw_feedbacks
		SET Value = vr_value,
			description = vr_description
	WHERE ApplicationID = vr_application_id AND FeedBackID = vr_feedback_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_arithmetic_delete_feedback;

CREATE PROCEDURE kw_arithmetic_delete_feedback
	vr_application_id	UUID,
	vr_feedback_id		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE kw_feedbacks
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND FeedBackID = vr_feedback_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_p_get_feedbacks_by_ids;

CREATE PROCEDURE kw_p_get_feedbacks_by_ids
	vr_application_id		UUID,
	vr_feedback_idsTemp	BigIntTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_feedback_ids BigIntTableType
	INSERT INTO vr_feedback_ids SELECT * FROM vr_feedback_idsTemp
	
	SELECT fb.feedback_id,
		   fb.knowledge_id,
		   fb.feedback_type_id,
		   fb.send_date,
		   fb.value,
		   fb.description,
		   usr.user_id,
		   usr.username,
		   usr.first_name,
		   usr.last_name
	FROM vr_feedback_ids AS external_ids  
		INNER JOIN kw_feedbacks AS fb
		ON fb.application_id = vr_application_id AND fb.feedback_id = external_ids.value
		INNER JOIN users_normal AS usr
		ON usr.application_id = vr_application_id AND usr.user_id = fb.user_id
	ORDER BY fb.send_date DESC
END;


DROP PROCEDURE IF EXISTS kw_get_feedbacks_by_ids;

CREATE PROCEDURE kw_get_feedbacks_by_ids
	vr_application_id		UUID,
	vr_strFeedBackIDs		varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_feedback_ids BigIntTableType
	
	INSERT INTO vr_feedback_ids
	SELECT DISTINCT ref.value FROM GFN_StrToBigIntTable(vr_strFeedBackIDs, vr_delimiter) AS ref

	EXEC kw_p_get_feedbacks_by_ids vr_application_id, vr_feedback_ids
END;


DROP PROCEDURE IF EXISTS kw_get_knowledge_feedbacks;

CREATE PROCEDURE kw_get_knowledge_feedbacks
	vr_application_id				UUID,
	vr_knowledge_id				UUID,
	vr_user_id						UUID,
	vr_feedback_type_id			 INTEGER,
	vr_sendDateLowerThreshold	 TIMESTAMP,
	vr_sendDateUpperThreshold	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_feedback_ids BigIntTableType
	
	INSERT INTO vr_feedback_ids
	SELECT fb.feedback_id
	FROM kw_feedbacks AS fb
		INNER JOIN users_normal AS usr
		ON usr.application_id = vr_application_id AND usr.user_id = fb.user_id
	WHERE fb.application_id = vr_application_id AND fb.knowledge_id = vr_knowledge_id AND 
		(vr_user_id IS NULL OR fb.user_id = vr_user_id) AND fb.deleted = FALSE AND
		(vr_feedback_type_id IS NULL OR fb.feedback_type_id = vr_feedback_type_id) AND
		(vr_sendDateLowerThreshold IS NULL OR fb.send_date >= vr_sendDateLowerThreshold) AND
		(vr_sendDateUpperThreshold IS NULL OR fb.send_date <= vr_sendDateUpperThreshold)

	EXEC kw_p_get_feedbacks_by_ids vr_application_id, vr_feedback_ids
END;


DROP PROCEDURE IF EXISTS kw_get_feedback_status;

CREATE PROCEDURE kw_get_feedback_status
	vr_application_id	UUID,
	vr_knowledge_id	UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1)
		SUM(CASE WHEN fb.feedback_type_id = 1 THEN fb.value ELSE 0 END) AS total_financial_feedbacks,
		SUM(CASE WHEN fb.feedback_type_id = 2 THEN fb.value ELSE 0 END) AS total_temporal_feedbacks,
		SUM(CASE WHEN fb.user_id = vr_user_id AND fb.feedback_type_id = 1 THEN fb.value ELSE 0 END) AS financial_feedback_status,
		SUM(CASE WHEN fb.user_id = vr_user_id AND fb.feedback_type_id = 2 THEN fb.value ELSE 0 END) AS temporal_feedback_status
	FROM kw_feedbacks AS fb
	WHERE fb.application_id = vr_application_id AND 
		fb.knowledge_id = vr_knowledge_id AND fb.deleted = FALSE
END;

/* end of Knowledge Feedbacks */


/* Necessary Items */

DROP PROCEDURE IF EXISTS kw_get_necessary_items;

CREATE PROCEDURE kw_get_necessary_items
	vr_application_id			UUID,
	vr_nodeTypeIDOrNodeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_nodeTypeIDOrNodeID = COALESCE((
		SELECT TOP(1) NodeTypeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeIDOrNodeID
	), vr_nodeTypeIDOrNodeID)
	
	SELECT ni.item_name
	FROM kw_necessary_items AS ni
	WHERE ni.application_id = vr_application_id AND 
		ni.node_type_id = vr_nodeTypeIDOrNodeID AND ni.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS kw_activate_necessary_item;

CREATE PROCEDURE kw_activate_necessary_item
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_itemName		varchar(50),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM kw_necessary_items
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_nodeTypeID AND ItemName = vr_itemName
	) BEGIN
		UPDATE kw_necessary_items
			SET LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_nodeTypeID AND ItemName = vr_itemName
	END
	ELSE BEGIN
		INSERT INTO kw_necessary_items (
			ApplicationID,
			NodeTypeID,
			ItemName,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			vr_application_id,
			vr_nodeTypeID,
			vr_itemName,
			vr_current_user_id,
			vr_now,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_deactive_necessary_item;

CREATE PROCEDURE kw_deactive_necessary_item
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_itemName		varchar(50),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE kw_necessary_items
		SET LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND 
		NodeTypeID = vr_nodeTypeID AND ItemName = vr_itemName
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS kw_check_necessary_items;

CREATE PROCEDURE kw_check_necessary_items
	vr_application_id	UUID,
	vr_node_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	-- meta data for NecessaryFieldsOfForm
	DECLARE vr_nodeTypeID UUID = (
		SELECT TOP(1) NodeTypeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	)
	
	DECLARE vr_element_limits TABLE (ElementID UUID, Necessary BOOLEAN)

	INSERT INTO vr_element_limits (ElementID, Necessary)
	SELECT el.element_id, COALESCE(el.necessary, FALSE)
	FROM fg_element_limits AS el
	WHERE el.application_id = vr_application_id AND 
		el.owner_id = vr_nodeTypeID AND el.deleted = FALSE
		
	DECLARE vr_has_form_limit BOOLEAN =
		CASE WHEN (SELECT COUNT(*) FROM vr_element_limits) > 0 THEN 1 ELSE 0 END
		
	DELETE vr_element_limits
	WHERE necessary = FALSE
	-- end of meta data for NecessaryFieldsOfForm
	
	DECLARE vr_items StringTableType
	
	;WITH X AS (
		SELECT TOP(1) *
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	)
	INSERT INTO vr_items (Value)
	SELECT x.item_name
	FROM (
			SELECT TOP(1) N'Abstract' AS item_name
			FROM X
			WHERE COALESCE(x.description, N'') <> N''
			
			UNION
			
			SELECT TOP(1) N'Keywords'
			FROM X
			WHERE COALESCE(x.tags, N'') <> N''
			
			UNION
			
			SELECT TOP(1) N'Wiki'
			FROM X
				INNER JOIN wk_titles AS t
				ON t.application_id = vr_application_id AND t.owner_id = x.node_id AND t.deleted = FALSE
				INNER JOIN wk_paragraphs AS p
				ON p.application_id = vr_application_id AND p.title_id = t.title_id AND p.deleted = FALSE AND
					(p.status = N'Accepted' OR p.status = N'CitationNeeded')
					
			UNION
			
			SELECT TOP(1) N'RelatedNodes'
			FROM X
				LEFT JOIN cn_view_out_related_nodes AS nr
				ON nr.application_id = vr_application_id AND 
					nr.node_id = x.node_id AND nr.related_node_id <> x.node_id
				LEFT JOIN cn_view_in_related_nodes AS nrin
				ON nrin.application_id = vr_application_id AND
					nrin.node_id = x.node_id AND nrin.related_node_id <> x.node_id
			WHERE nr.node_id IS NOT NULL OR nrin.node_id IS NOT NULL
				
			UNION
			
			SELECT TOP(1) N'Attachments'
			FROM X
				INNER JOIN dct_files AS att
				ON att.application_id = vr_application_id AND att.owner_id = x.node_id AND att.deleted = FALSE
			
			UNION

			SELECT TOP(1) N'DocumentTree'
			FROM X
			WHERE x.document_tree_node_id IS NOT NULL
			
			UNION
			
			SELECT TOP(1) N'NecessaryFieldsOfForm'
			WHERE NOT EXISTS (
					SELECT TOP(1) 1
					FROM X INNER JOIN 
						fg_form_owners AS o
						ON o.application_id = vr_application_id AND 
							o.owner_id = x.node_type_id AND o.deleted = FALSE
						INNER JOIN fg_form_instances AS i
						ON i.application_id = vr_application_id AND 
							i.form_id = o.form_id AND i.owner_id = vr_node_id AND 
							i.deleted = FALSE
						INNER JOIN fg_extended_form_elements AS fe
						ON fe.application_id = vr_application_id AND 
							fe.form_id = o.form_id AND fe.deleted = FALSE AND
							(vr_has_form_limit = 1 OR fe.necessary = TRUE)
						LEFT JOIN fg_instance_elements AS e
						ON e.application_id = vr_application_id AND 
							e.instance_id = i.instance_id AND 
							e.ref_element_id = fe.element_id AND e.deleted = FALSE
					WHERE (
							COALESCE(vr_has_form_limit, 0) = 0 OR 
							fe.element_id IN (SELECT ElementID FROM vr_element_limits)
						) AND
						COALESCE(fg_fn_to_string(
							vr_application_id,
							e.element_id,
							e.type,
							e.text_value, 
							e.float_value,
							e.bit_value, 
							e.date_value
						), N'') = N''
				)
		) AS x
		
	SELECT i.value AS item_name
	FROM vr_items AS i
END;

/* end of Necessary Items */

DROP PROCEDURE IF EXISTS qa_add_new_workflow;

CREATE PROCEDURE qa_add_new_workflow
	vr_application_id	UUID,
    vr_workflow_id 	UUID,
    vr_name		 VARCHAR(200),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET vr_name = gfn_verify_string(vr_name)
	
	DECLARE vr_seqNo INTEGER = COALESCE((
		SELECT MAX(SequenceNumber) 
		FROM qa_workflows
		WHERE ApplicationID = vr_application_id
	), 0) + 1

    INSERT INTO qa_workflows (
		application_id,
		workflow_id,
        name,
        sequence_number,
        initial_check_needed,
        final_confirmation_needed,
        removable_after_confirmation,
        disable_comments,
        disable_question_likes,
        disable_answer_likes,
        disable_comment_likes,
        disable_best_answer,
        creator_user_id,
        creation_date,
        deleted
    )
    VALUES (
		vr_application_id,
		vr_workflow_id,
        vr_name,
        vr_seqNo,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        vr_current_user_id,
        vr_now,
        0
    )
    
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_rename_workflow;

CREATE PROCEDURE qa_rename_workflow
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_name		 VARCHAR(200),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	
	UPDATE qa_workflows
	SET Name = vr_name,
		LastModifierUserID = vr_current_user_id,
		LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_description;

CREATE PROCEDURE qa_set_workflow_description
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_description VARCHAR(2000),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE qa_workflows
	SET description = vr_description,
		LastModifierUserID = vr_current_user_id,
		LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflows_order;

CREATE PROCEDURE qa_set_workflows_order
	vr_application_id	UUID,
	vr_strWorkFlowIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids TABLE (
		SequenceNo INTEGER identity(1, 1) primary key, 
		WorkFlowID UUID
	)
	
	INSERT INTO vr_workflow_ids (WorkFlowID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strWorkFlowIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_workflow_ids (WorkFlowID)
	SELECT w.workflow_id
	FROM vr_workflow_ids AS ref
		RIGHT JOIN qa_workflows AS w
		ON w.application_id = vr_application_id AND w.workflow_id = ref.workflow_id
	WHERE w.application_id = vr_application_id AND ref.workflow_id IS NULL
	ORDER BY w.sequence_number
	
	UPDATE qa_workflows
		SET SequenceNumber = ref.sequence_no
	FROM vr_workflow_ids AS ref
		INNER JOIN qa_workflows AS w
		ON w.workflow_id = ref.workflow_id
	WHERE w.application_id = vr_application_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_initial_check_needed;

CREATE PROCEDURE qa_set_workflow_initial_check_needed
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET InitialCheckNeeded = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_final_confirmation_needed;

CREATE PROCEDURE qa_set_workflow_final_confirmation_needed
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET FinalConfirmationNeeded = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_action_deadline;

CREATE PROCEDURE qa_set_workflow_action_deadline
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 INTEGER,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET ActionDeadline = CASE WHEN COALESCE(vr_value, 0) <= 0 THEN 0 ELSE vr_value END
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_answer_by;

CREATE PROCEDURE qa_set_workflow_answer_by
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value			varchar(50),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET AnswerBy = vr_value
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_publish_after;

CREATE PROCEDURE qa_set_workflow_publish_after
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value			varchar(50),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET PublishAfter = vr_value
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_removable_after_confirmation;

CREATE PROCEDURE qa_set_workflow_removable_after_confirmation
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET RemovableAfterConfirmation = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_node_select_type;

CREATE PROCEDURE qa_set_workflow_node_select_type
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value			varchar(50),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET NodeSelectType = vr_value
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_disable_comments;

CREATE PROCEDURE qa_set_workflow_disable_comments
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET DisableComments = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_disable_question_likes;

CREATE PROCEDURE qa_set_workflow_disable_question_likes
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET DisableQuestionLikes = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_disable_answer_likes;

CREATE PROCEDURE qa_set_workflow_disable_answer_likes
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET DisableAnswerLikes = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_disable_comment_likes;

CREATE PROCEDURE qa_set_workflow_disable_comment_likes
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET DisableCommentLikes = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_workflow_disable_best_answer;

CREATE PROCEDURE qa_set_workflow_disable_best_answer
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_value		 BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET DisableBestAnswer = COALESCE(vr_value, 0)
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_remove_workflow;

CREATE PROCEDURE qa_remove_workflow
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_recycle_workflow;

CREATE PROCEDURE qa_recycle_workflow
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_workflows
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_p_get_workflows_by_ids;

CREATE PROCEDURE qa_p_get_workflows_by_ids
	vr_application_id		UUID,
	vr_workflow_idsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids KeyLessGuidTableType
	INSERT INTO vr_workflow_ids (Value) SELECT Value FROM vr_workflow_idsTemp
	
	SELECT	w.workflow_id,
			w.name,
			w.description,
			w.initial_check_needed,
			w.final_confirmation_needed,
			w.action_deadline,
			w.answer_by,
			w.publish_after,
			w.removable_after_confirmation,
			w.node_select_type,
			w.disable_comments,
			w.disable_question_likes,
			w.disable_answer_likes,
			w.disable_comment_likes,
			w.disable_best_answer
	FROM vr_workflow_ids AS i
		INNER JOIN qa_workflows AS w
		ON w.application_id = vr_application_id AND w.workflow_id = i.value
	ORDER BY i.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_workflows;

CREATE PROCEDURE qa_get_workflows
	vr_application_id	UUID,
	vr_archive	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids KeyLessGuidTableType
	
	INSERT INTO vr_workflow_ids (Value)
	SELECT	w.workflow_id
	FROM qa_workflows AS w
	WHERE w.application_id = vr_application_id AND w.deleted = COALESCE(vr_archive, 0)
	ORDER BY COALESCE(w.sequence_number, 1000000) ASC, w.creation_date ASC
	
	EXEC qa_p_get_workflows_by_ids vr_application_id, vr_workflow_ids
END;


DROP PROCEDURE IF EXISTS qa_get_workflow;

CREATE PROCEDURE qa_get_workflow
	vr_application_id						UUID,
	vr_workflow_idOrQuestionIDOrAnswerID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids KeyLessGuidTableType
	
	SELECT TOP(1) vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(q.workflow_id, vr_workflow_idOrQuestionIDOrAnswerID)
	FROM qa_answers AS a
		INNER JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = a.question_id
	WHERE a.application_id = vr_application_id AND a.answer_id = vr_workflow_idOrQuestionIDOrAnswerID
	
	SELECT TOP(1) vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(q.workflow_id, vr_workflow_idOrQuestionIDOrAnswerID)
	FROM qa_questions AS q
	WHERE q.application_id = vr_application_id AND q.question_id = vr_workflow_idOrQuestionIDOrAnswerID
	
	INSERT INTO vr_workflow_ids (Value)
	VALUES (vr_workflow_idOrQuestionIDOrAnswerID)
	
	EXEC qa_p_get_workflows_by_ids vr_application_id, vr_workflow_ids
END;


DROP PROCEDURE IF EXISTS qa_is_workflow;

CREATE PROCEDURE qa_is_workflow
	vr_application_id	UUID,
    vr_strIDs			varchar(max),
    vr_delimter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT w.workflow_id AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimter) AS ref
		INNER JOIN qa_workflows AS w
		ON w.application_id = vr_application_id AND w.workflow_id = ref.value
END;


DROP PROCEDURE IF EXISTS qa_add_workflow_admin;

CREATE PROCEDURE qa_add_workflow_admin
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_workflow_id 	UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_admins
	SET LastModifierUserID = vr_current_user_id,
		LastModificationDate = vr_now,
	 deleted = FALSE
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id AND
		((WorkFlowID IS NULL AND vr_workflow_id IS NULL) OR (WorkFlowID = vr_workflow_id))
	
    IF @vr_rowcount = 0 BEGIN
		INSERT INTO qa_admins (
			ApplicationID,
			UserID,
			WorkFlowID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			vr_application_id,
			vr_user_id,
			vr_workflow_id,
			vr_current_user_id,
			vr_now,
			0
		)
		
		SELECT @vr_rowcount
    END
    ELSE SELECT 1
END;


DROP PROCEDURE IF EXISTS qa_remove_workflow_admin;

CREATE PROCEDURE qa_remove_workflow_admin
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_workflow_id 	UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_admins
	SET deleted = TRUE,
		LastModifierUserID = vr_current_user_id,
		LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id AND
		((WorkFlowID IS NULL AND vr_workflow_id IS NULL) OR (WorkFlowID = vr_workflow_id))
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_is_workflow_admin;

CREATE PROCEDURE qa_is_workflow_admin
	vr_application_id						UUID,
	vr_user_id								UUID,
    vr_workflow_idOrQuestionIDOrAnswerID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_workflow_idOrQuestionIDOrAnswerID IS NOT NULL BEGIN
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(q.workflow_id, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_answers AS a
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = a.question_id
		WHERE a.application_id = vr_application_id AND a.answer_id = vr_workflow_idOrQuestionIDOrAnswerID
		
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(WorkFlowID, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_questions
		WHERE ApplicationID = vr_application_id AND QuestionID = vr_workflow_idOrQuestionIDOrAnswerID
	END
	
	SELECT 
		CASE 
			WHEN EXISTS (
				SELECT TOP(1) UserID
				FROM qa_admins
				WHERE ApplicationID = vr_application_id AND UserID = vr_user_id AND
					(
						(WorkFlowID IS NULL AND vr_workflow_idOrQuestionIDOrAnswerID IS NULL) OR 
						(WorkFlowID = vr_workflow_idOrQuestionIDOrAnswerID)
					) AND deleted = FALSE
			) THEN 1
			ELSE 0 
		END
			
END;


DROP PROCEDURE IF EXISTS qa_get_workflow_admin_ids;

CREATE PROCEDURE qa_get_workflow_admin_ids
	vr_application_id						UUID,
    vr_workflow_idOrQuestionIDOrAnswerID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_workflow_idOrQuestionIDOrAnswerID IS NOT NULL BEGIN
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(q.workflow_id, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_answers AS a
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = a.question_id
		WHERE a.application_id = vr_application_id AND a.answer_id = vr_workflow_idOrQuestionIDOrAnswerID
		
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(WorkFlowID, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_questions
		WHERE ApplicationID = vr_application_id AND QuestionID = vr_workflow_idOrQuestionIDOrAnswerID
	END
	
	SELECT ad.user_id AS id
	FROM qa_admins AS ad
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ad.user_id AND un.is_approved = TRUE
	WHERE ad.application_id = vr_application_id AND
		(
			(ad.workflow_id IS NULL AND vr_workflow_idOrQuestionIDOrAnswerID IS NULL) OR 
			(ad.workflow_id = vr_workflow_idOrQuestionIDOrAnswerID)
		) AND ad.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS qa_set_candidate_relations;

CREATE PROCEDURE qa_set_candidate_relations
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_strNodeTypeIDs	varchar(max),
	vr_strNodeIDs		varchar(max),
	vr_delimiter		char,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_iDs Table(NodeTypeID UUID, NodeID UUID)
	
	INSERT INTO vr_iDs (NodeTypeID)
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_iDs (NodeID)
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_existingIDs Table(NodeTypeID UUID, NodeID UUID)
	
	INSERT INTO vr_existingIDs(NodeTypeID, NodeID)
	SELECT cr.node_type_id, cr.node_id
	FROM vr_iDs AS ref
		INNER JOIN qa_candidate_relations AS cr
		ON cr.node_type_id = ref.node_type_id OR cr.node_id = ref.node_id
	WHERE cr.application_id = vr_application_id AND cr.workflow_id = vr_workflow_id
	
	DECLARE vr_count INTEGER = (SELECT COUNT(*) FROM vr_iDs)
	DECLARE vr_existingCount INTEGER = (SELECT COUNT(*) FROM vr_existingIDs)
	
	IF EXISTS(SELECT * FROM qa_candidate_relations
		WHERE WorkFlowID = vr_workflow_id) BEGIN
		
		UPDATE qa_candidate_relations
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = TRUE
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr_existingCount > 0 BEGIN
		UPDATE CR
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		FROM vr_existingIDs AS ref
			INNER JOIN qa_candidate_relations AS cr
			ON cr.node_type_id = ref.node_type_id OR cr.node_id = ref.node_id
		WHERE cr.application_id = vr_application_id AND cr.workflow_id = vr_workflow_id
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr_count > vr_existingCount BEGIN
		INSERT INTO qa_candidate_relations(
			ApplicationID,
			ID,
			WorkFlowID,
			NodeID,
			NodeTypeID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT vr_application_id, gen_random_uuid(), vr_workflow_id, ref.node_id, ref.node_type_id, 
			vr_creator_user_id, vr_creation_date, 0
		FROM (
				SELECT i.*
				FROM vr_iDs AS i
					LEFT JOIN vr_existingIDs AS e
					ON i.node_id = e.node_id OR i.node_type_id = e.node_type_id
				WHERE e.node_id IS NULL AND e.node_type_id IS NULL
			) AS ref
		
		IF @vr_rowcount <= 0 BEGIN
		select 6
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS qa_get_candidate_node_relation_ids;

CREATE PROCEDURE qa_get_candidate_node_relation_ids
	vr_application_id						UUID,
	vr_workflow_idOrQuestionIDOrAnswerID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_workflow_idOrQuestionIDOrAnswerID IS NOT NULL BEGIN
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(q.workflow_id, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_answers AS a
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = a.question_id
		WHERE a.application_id = vr_application_id AND a.answer_id = vr_workflow_idOrQuestionIDOrAnswerID
		
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(WorkFlowID, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_questions
		WHERE ApplicationID = vr_application_id AND QuestionID = vr_workflow_idOrQuestionIDOrAnswerID
	END
	
	DECLARE vr_workflow_id UUID = vr_workflow_idOrQuestionIDOrAnswerID
	
	SELECT NodeID AS id
	FROM qa_candidate_relations
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND NodeID IS NOT NULL AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS qa_get_candidate_node_type_relation_ids;

CREATE PROCEDURE qa_get_candidate_node_type_relation_ids
	vr_application_id						UUID,
	vr_workflow_idOrQuestionIDOrAnswerID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_workflow_idOrQuestionIDOrAnswerID IS NOT NULL BEGIN
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(q.workflow_id, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_answers AS a
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = a.question_id
		WHERE a.application_id = vr_application_id AND a.answer_id = vr_workflow_idOrQuestionIDOrAnswerID
		
		SELECT vr_workflow_idOrQuestionIDOrAnswerID = COALESCE(WorkFlowID, vr_workflow_idOrQuestionIDOrAnswerID)
		FROM qa_questions
		WHERE ApplicationID = vr_application_id AND QuestionID = vr_workflow_idOrQuestionIDOrAnswerID
	END
	
	DECLARE vr_workflow_id UUID = vr_workflow_idOrQuestionIDOrAnswerID
	
	SELECT NodeTypeID AS id
	FROM qa_candidate_relations
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND NodeTypeID IS NOT NULL AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS qa_create_faq_category;

CREATE PROCEDURE qa_create_faq_category
	vr_application_id	UUID,
	vr_category_id		UUID,
	vr_parent_id		UUID,
	vr_name		 VARCHAR(200),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	
	DECLARE vr_seqNo INTEGER = COALESCE((
		SELECT MAX(SequenceNumber) 
		FROM qa_faq_categories
		WHERE ApplicationID = vr_application_id AND 
			((ParentID IS NULL AND vr_parent_id IS NULL) OR (ParentID = vr_parent_id))
	), 0) + 1
	
	INSERT INTO qa_faq_categories (
		ApplicationID,
		CategoryID,
		ParentID,
		SequenceNumber,
		Name,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		vr_application_id,
		vr_category_id,
		vr_parent_id,
		vr_seqNo,
		vr_name,
		vr_current_user_id,
		vr_now,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_rename_faq_category;

CREATE PROCEDURE qa_rename_faq_category
	vr_application_id	UUID,
	vr_category_id		UUID,
	vr_name		 VARCHAR(200),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	
	UPDATE qa_faq_categories
	SET Name = vr_name,
		LastModifierUserID = vr_current_user_id,
		LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND CategoryID = vr_category_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_move_faq_categories;

CREATE PROCEDURE qa_move_faq_categories
	vr_application_id	UUID,
    vr_strCategoryIDs	varchar(max),
	vr_delimiter		char,
    vr_new_parent_id	UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_category_ids GuidTableType
	INSERT INTO vr_category_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strCategoryIDs, vr_delimiter) AS ref
	
	DECLARE vr_parent_hierarchy NodesHierarchyTableType
	
	IF vr_new_parent_id IS NOT NULL BEGIN
		INSERT INTO vr_parent_hierarchy
		SELECT *
		FROM qa_fn_get_parent_category_hierarchy(vr_application_id, vr_new_parent_id)
	END
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM vr_parent_hierarchy AS p
			INNER JOIN vr_category_ids AS c
			ON c.value = p.node_id
	) BEGIN
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	UPDATE C
		SET LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now,
			ParentID = vr_new_parent_id
	FROM vr_category_ids AS ref
		INNER JOIN qa_faq_categories AS c
		ON c.category_id = ref.value
	WHERE c.application_id = vr_application_id AND 
		(vr_new_parent_id IS NULL OR c.category_id <> vr_new_parent_id)
	
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_faq_categories_order;

CREATE PROCEDURE qa_set_faq_categories_order
	vr_application_id	UUID,
	vr_strCategoryIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_category_ids TABLE (
		SequenceNo INTEGER identity(1, 1) primary key, 
		CategoryID UUID
	)
	
	INSERT INTO vr_category_ids (CategoryID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strCategoryIDs, vr_delimiter) AS ref
	
	DECLARE vr_parent_id UUID = NULL
	
	SELECT TOP(1) vr_parent_id = ParentID
	FROM qa_faq_categories
	WHERE ApplicationID = vr_application_id AND 
		CategoryID = (SELECT TOP (1) ref.category_id FROM vr_category_ids AS ref)
	
	INSERT INTO vr_category_ids (CategoryID)
	SELECT c.category_id
	FROM vr_category_ids AS ref
		RIGHT JOIN qa_faq_categories AS c
		ON c.application_id = vr_application_id AND c.category_id = ref.category_id
	WHERE c.application_id = vr_application_id AND ((c.parent_id IS NULL AND vr_parent_id IS NULL) OR c.parent_id = vr_parent_id) AND 
		ref.category_id IS NULL
	ORDER BY c.sequence_number
	
	UPDATE qa_faq_categories
		SET SequenceNumber = ref.sequence_no
	FROM vr_category_ids AS ref
		INNER JOIN qa_faq_categories AS c
		ON c.category_id = ref.category_id
	WHERE c.application_id = vr_application_id AND 
		((c.parent_id IS NULL AND vr_parent_id IS NULL) OR c.parent_id = vr_parent_id)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_remove_faq_categories;

CREATE PROCEDURE qa_remove_faq_categories
	vr_application_id		UUID,
    vr_strCategoryIDs		varchar(max),
    vr_delimiter			char,
    vr_remove_hierarchy BOOLEAN,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_category_ids GuidTableType
	
	INSERT INTO vr_category_ids
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strCategoryIDs, vr_delimiter) AS ref
	
	IF COALESCE(vr_remove_hierarchy, 0) = 0 BEGIN
		UPDATE C
			SET deleted = TRUE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		FROM vr_category_ids AS ref
			INNER JOIN qa_faq_categories AS c
			ON c.category_id = ref.value
		WHERE c.application_id = vr_application_id AND c.deleted = FALSE
			
		DECLARE vr__result INTEGER = @vr_rowcount
			
		UPDATE qa_faq_categories
			SET ParentID = NULL
		WHERE ApplicationID = vr_application_id AND ParentID IN(SELECT * FROM vr_category_ids)
		
		SELECT vr__result
	END
	ELSE BEGIN
		UPDATE C
			SET deleted = TRUE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		FROM qa_fn_get_child_categories_hierarchy(vr_application_id, vr_category_ids) AS ref
			INNER JOIN qa_faq_categories AS c
			ON c.category_id = ref.category_id
		WHERE c.application_id = vr_application_id
			
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS qa_get_child_faq_categories;

CREATE PROCEDURE qa_get_child_faq_categories
	vr_application_id		UUID,
    vr_parent_id			UUID,
    vr_current_user_id		UUID,
    vr_check_access	 BOOLEAN,
    vr_default_privacy		varchar(50),
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_categories Table (
		CategoryID UUID primary key clustered, 
		Name VARCHAR(200),
		SequenceNumber INTEGER,
		HasChild BOOLEAN
	)
	
	INSERT INTO vr_categories (CategoryID, Name, SequenceNumber, HasChild)
	SELECT	c.category_id, 
			c.name, 
			c.sequence_number,
			(
				SELECT CAST(1 AS boolean)
				WHERE EXISTS (
						SELECT TOP(1) *
						FROM qa_faq_categories AS p
						WHERE p.application_id = vr_application_id AND 
							p.parent_id = c.category_id AND p.deleted = FALSE
					)
			) AS has_child
	FROM qa_faq_categories AS c
	WHERE c.application_id = vr_application_id AND c.deleted = FALSE AND
		((c.parent_id IS NULL AND vr_parent_id IS NULL) OR (c.parent_id = vr_parent_id))
		
	IF vr_check_access = 1 BEGIN
		DECLARE vr_c_ids KeyLessGuidTableType
		
		INSERT INTO vr_c_ids (Value)
		SELECT c.category_id
		FROM vr_categories AS c
			
		DECLARE	vr_permission_types StringPairTableType
		
		INSERT INTO vr_permission_types (FirstValue, SecondValue)
		VALUES (N'View', vr_default_privacy)
		
		DELETE C
		FROM vr_categories AS c
			LEFT JOIN prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_c_ids, N'FAQCategory', vr_now, vr_permission_types) AS a
			ON a.id = c.category_id
		WHERE a.id IS NULL
	END
	
	SELECT	c.category_id,
			c.name,
			c.has_child
	FROM vr_categories AS c
	ORDER BY c.sequence_number ASC, c.category_id ASC
END;


DROP PROCEDURE IF EXISTS qa_is_faq_category;

CREATE PROCEDURE qa_is_faq_category
	vr_application_id	UUID,
    vr_strIDs			varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT c.category_id AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
		INNER JOIN qa_faq_categories AS c
		ON c.application_id = vr_application_id AND c.category_id = ref.value
END;


DROP PROCEDURE IF EXISTS qa_add_faq_items;

CREATE PROCEDURE qa_add_faq_items
	vr_application_id	UUID,
    vr_category_id		UUID,
    vr_strQuestionIDs	varchar(max),
    vr_delimiter		char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_question_ids TABLE (Seq INTEGER IDENTITY(1, 1), QuestionID UUID)
	
	INSERT INTO vr_question_ids (QuestionID)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strQuestionIDs, vr_delimiter) AS ref
		LEFT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = vr_category_id AND i.question_id = ref.value
	WHERE i.question_id IS NULL OR i.deleted = TRUE
	
	DECLARE vr_seqNo INTEGER = COALESCE((
		SELECT MAX(SequenceNumber) 
		FROM qa_faq_items
		WHERE ApplicationID = vr_application_id AND CategoryID = vr_category_id
	), 0)
	
	UPDATE I
		SET deleted = FALSE,
			SequenceNumber = i_ds.seq + vr_seqNo,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_question_ids AS i_ds
		INNER JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = vr_category_id AND i.question_id = i_ds.question_id
			
	INSERT INTO qa_faq_items (
		ApplicationID,
		CategoryID,
		QuestionID,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	) 
	SELECT	vr_application_id, 
			vr_category_id, 
			i_ds.question_id, 
			i_ds.seq + vr_seqNo, 
			vr_current_user_id, 
			vr_now, 
			0
	FROM vr_question_ids AS i_ds
		LEFT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = vr_category_id AND i.question_id = i_ds.question_id
	WHERE i.question_id IS NULL
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS qa_add_question_to_faq_categories;

CREATE PROCEDURE qa_add_question_to_faq_categories
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_strCategoryIDs	varchar(max),
    vr_delimiter		char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_category_ids TABLE (CategoryID UUID, Seq INTEGER)
	
	;WITH C (CategoryID)
 AS 
	(
		SELECT DISTINCT c.value AS category_id
		FROM gfn_str_to_guid_table(vr_strCategoryIDs, vr_delimiter) AS c
			LEFT JOIN qa_faq_items AS i
			ON i.application_id = vr_application_id AND 
				i.category_id = c.value AND i.question_id = vr_question_id
		WHERE i.category_id IS NULL OR i.deleted = TRUE
	)
	INSERT INTO vr_category_ids (CategoryID, Seq)
	SELECT c.category_id, COALESCE(MAX(i.sequence_number), 0) + 1 AS seq
	FROM C
		LEFT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND i.category_id = c.category_id
	GROUP BY c.category_id
	
	UPDATE I
		SET deleted = FALSE,
			SequenceNumber = i_ds.seq,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_category_ids AS i_ds
		INNER JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = i_ds.category_id AND i.question_id = vr_question_id
			
	INSERT INTO qa_faq_items (
		ApplicationID,
		CategoryID,
		QuestionID,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	) 
	SELECT	vr_application_id, 
			i_ds.category_id, 
			vr_question_id, 
			i_ds.seq, 
			vr_current_user_id, 
			vr_now, 
			0
	FROM vr_category_ids AS i_ds
		LEFT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = i_ds.category_id AND i.question_id = vr_question_id
	WHERE i.category_id IS NULL
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS qa_remove_faq_item;

CREATE PROCEDURE qa_remove_faq_item
	vr_application_id	UUID,
    vr_category_id		UUID,
    vr_question_id		UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_faq_items
	SET deleted = TRUE,
		LastModifierUserID = vr_current_user_id,
		LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND 
		CategoryID = vr_category_id AND QuestionID = vr_question_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_faq_items_order;

CREATE PROCEDURE qa_set_faq_items_order
	vr_application_id	UUID,
	vr_category_id		UUID,
	vr_strQuestionIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_question_ids TABLE (
		SequenceNo INTEGER identity(1, 1) primary key, 
		QuestionID UUID
	)
	
	INSERT INTO vr_question_ids (QuestionID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strQuestionIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_question_ids (QuestionID)
	SELECT i.question_id
	FROM vr_question_ids AS ref
		RIGHT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND i.question_id = ref.question_id
	WHERE i.application_id = vr_application_id AND i.category_id = vr_category_id AND ref.question_id IS NULL
	ORDER BY i.sequence_number
	
	UPDATE qa_faq_items
		SET SequenceNumber = ref.sequence_no
	FROM vr_question_ids AS ref
		INNER JOIN qa_faq_items AS i
		ON i.question_id = ref.question_id
	WHERE i.application_id = vr_application_id AND i.category_id = vr_category_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_add_question;

CREATE PROCEDURE qa_add_question
	vr_application_id		UUID,
    vr_question_id 		UUID,
    vr_title			 VARCHAR(500),
    vr_description	 VARCHAR(max),
    vr_status				varchar(20),
    vr_publication_date TIMESTAMP,
    vr_strNodeIDs			varchar(max),
    vr_delimiter			char,
    vr_workflow_id			UUID,
    vr_adminID			UUID,
    vr_current_user_id		UUID,
    vr_now   			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON

	SET vr_title = gfn_verify_string(vr_title)
	SET vr_description = gfn_verify_string(vr_description)

    INSERT INTO qa_questions (
		application_id,
        question_id,
		title,
		description,
		status,
		publication_date,
		workflow_id,
		sender_user_id,
		send_date,
		deleted
    )
    VALUES (
		vr_application_id,
        vr_question_id,
        vr_title,
        vr_description,
        vr_status,
        vr_publication_date,
        vr_workflow_id,
        vr_current_user_id,
        vr_now,
        0
    )
    
    /*     convert string ids to guid     */	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strNodeIDs, vr_delimiter) AS ref
	/*     end of convert string ids to guid     */
    
    /*     insert related nodes     */
    DECLARE vr__nodes_count INTEGER
    SET vr__nodes_count = (SELECT COUNT(*) FROM vr_node_ids)
    
    INSERT INTO qa_related_nodes(
		ApplicationID,
		NodeID, 
		QuestionID, 
		CreatorUserID,
		CreationDate,
		Deleted
	)
    SELECT vr_application_id, ref.value, vr_question_id, vr_current_user_id, vr_now, 0
    FROM vr_node_ids AS ref
    
    IF vr__nodes_count > 0 AND @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
    END
    /*     end of insert related nodes     */
    
    
    SELECT (1 + vr__nodes_count)
    
    -- Send new dashboards
    IF vr_adminID IS NOT NULL BEGIN
		DECLARE vr_dashboards DashboardTableType
		
		INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate)
		VALUES (vr_adminID, vr_question_id, vr_question_id, N'Question', N'Admin', 0, vr_now)
		
		DECLARE vr__result INTEGER = 0
		
		EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
		ELSE BEGIN
			SELECT * 
			FROM vr_dashboards
		END
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS qa_edit_question_title;

CREATE PROCEDURE qa_edit_question_title
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_title		 VARCHAR(500),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	
	UPDATE qa_questions
		SET title = vr_title,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_edit_question_description;

CREATE PROCEDURE qa_edit_question_description
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_description VARCHAR(max),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE qa_questions
		SET description = vr_description,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_is_question;

CREATE PROCEDURE qa_is_question
	vr_application_id	UUID,
    vr_iD				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) CAST(1 AS integer)
	FROM qa_questions
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_iD
END;


DROP PROCEDURE IF EXISTS qa_is_answer;

CREATE PROCEDURE qa_is_answer
	vr_application_id	UUID,
    vr_iD				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) CAST(1 AS integer)
	FROM qa_answers
	WHERE ApplicationID = vr_application_id AND AnswerID = vr_iD
END;


DROP PROCEDURE IF EXISTS qa_confirm_question;

CREATE PROCEDURE qa_confirm_question
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE qa_questions
		SET status = N'GettingAnswers',
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_set_the_best_answer;

CREATE PROCEDURE qa_set_the_best_answer
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_answerID		UUID,
    vr_publish	 BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE qa_questions
		SET BestAnswerID = vr_answerID,
			PublicationDate = CASE WHEN vr_publish = 1
				THEN COALESCE(PublicationDate, vr_now) ELSE PublicationDate END,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE vr_answerID IS NOT NULL AND ApplicationID = vr_application_id AND QuestionID = vr_question_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- remove dashboards
	IF vr_publish = 1 BEGIN
		DECLARE vr__result INTEGER = 0
    
		EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
			NULL, vr_question_id, NULL, N'Question', NULL, 
			vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	-- end of remove dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS qa_set_question_status;

CREATE PROCEDURE qa_set_question_status
	vr_application_id		UUID,
    vr_question_id	 		UUID,
    vr_status				varchar(50),
    vr_publish		 BOOLEAN,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON

    UPDATE qa_questions
		SET status = vr_status,
			PublicationDate = CASE WHEN vr_publish = 1
				THEN COALESCE(PublicationDate, vr_now) ELSE PublicationDate END,
			LastModifierUserID = COALESCE(vr_current_user_id, LastModifierUserID),
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- remove dashboards
	IF vr_publish = 1 BEGIN
		DECLARE vr__result INTEGER = 0
    
		EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
			NULL, vr_question_id, NULL, N'Question', NULL, 
			vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	-- end of remove dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS qa_remove_question;

CREATE PROCEDURE qa_remove_question
	vr_application_id		UUID,
    vr_question_id	 		UUID,
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    UPDATE qa_questions
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_p_get_questions_by_ids;

CREATE PROCEDURE qa_p_get_questions_by_ids
	vr_application_id		UUID,
    vr_question_idsTemp	KeyLessGuidTableType readonly,
    vr_current_user_id		UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_question_ids KeyLessGuidTableType
	INSERT INTO vr_question_ids (Value) SELECT Value FROM vr_question_idsTemp
	
	SELECT	q.question_id,
			q.workflow_id,
			q.title,
			q.description,
			q.send_date,
			q.best_answer_id,
			q.sender_user_id,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			q.status,
			q.publication_date,
			(
				SELECT COUNT(a.answer_id)
				FROM qa_answers AS a
				WHERE a.application_id = vr_application_id AND 
					a.question_id = q.question_id AND a.deleted = FALSE
			) AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = q.question_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = q.question_id AND l.like = FALSE
			) AS dislikes_count,
			(
				SELECT TOP(1) l.like
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = q.question_id AND l.user_id = vr_current_user_id
			) AS like_status,
			(
				SELECT TOP(1) CAST(1 AS boolean)
				FROM rv_followers AS f
				WHERE f.application_id = vr_application_id AND 
					f.followed_id = q.question_id AND f.user_id = vr_current_user_id
			) AS follow_status
	FROM vr_question_ids AS i_ds
		INNER JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = i_ds.value
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = q.sender_user_id
	ORDER BY i_ds.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_questions_by_ids;

CREATE PROCEDURE qa_get_questions_by_ids
	vr_application_id		UUID,
    vr_strQuestionIDs		varchar(max),
    vr_delimiter			char,
    vr_current_user_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_question_ids KeyLessGuidTableType
	
	INSERT INTO vr_question_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strQuestionIDs, vr_delimiter) AS ref
	
	EXEC qa_p_get_questions_by_ids vr_application_id, vr_question_ids, vr_current_user_id
END;


DROP PROCEDURE IF EXISTS qa_get_related_questions;

CREATE PROCEDURE qa_get_related_questions
	vr_application_id		UUID,
    vr_user_id		 		UUID,
    vr_groups			 BOOLEAN,
	vr_expertise_domains BOOLEAN,
	vr_favorites		 BOOLEAN,
	vr_properties		 BOOLEAN,
	vr_from_friends	 BOOLEAN,
	vr_count			 INTEGER,
	vr_lower_boundary		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		questions.*,
		(questions.row_number + questions.rev_row_number - 1) AS total_count,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
			WHERE a.application_id = vr_application_id AND 
				a.question_id = questions.question_id AND a.deleted = FALSE
		) AS answers_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = TRUE
		) AS likes_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = FALSE
		) AS dislikes_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY MAX(qs.send_date) DESC, qs.question_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY MAX(qs.send_date) ASC, qs.question_id DESC) AS rev_row_number,
					qs.question_id,
					MAX(qs.title) AS title,
					MAX(qs.send_date) AS send_date,
					CAST(MAX(CAST(qs.sender_user_id AS varchar(50))) AS uuid) AS sender_user_id,
					CAST(MAX(qs.has_best_answer) AS boolean) AS has_best_answer,
					MAX(qs.status) AS status,
					COUNT(qs.related_node_id) AS related_nodes_count,
					CAST(MAX(qs.is_group) AS boolean) AS is_group,
					CAST(MAX(qs.is_expertise) AS boolean) AS is_expertise_domain,
					CAST(MAX(qs.is_favorite) AS boolean) AS is_favorite,
					CAST(MAX(qs.is_property) AS boolean) AS is_property,
					CAST(MAX(qs.from_friend) AS boolean) AS from_friend
			FROM (
					SELECT	q.question_id, 
							q.title,
							q.send_date,
							q.sender_user_id,
							(CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS has_best_answer,
							q.status,
							nodes.node_id AS related_node_id,
							nodes.is_group,
							nodes.is_expertise,
							nodes.is_favorite,
							nodes.is_property,
							0 AS from_friend
					FROM (
							SELECT	x.node_id, 
									MAX(x.is_group) AS is_group, 
									MAX(x.is_expertise) AS is_expertise, 
									MAX(x.is_favorite) AS is_favorite, 
									MAX(x.is_property) AS is_property
							FROM (
									SELECT NodeID, 1 AS is_group, 0 AS is_expertise, 0 AS is_favorite, 0 AS is_property
									FROM cn_view_node_members
									WHERE vr_groups = 1 AND ApplicationID = vr_application_id AND UserID = vr_user_id AND
										ISNULL.is_pending, FALSE = 0
										
									UNION ALL

									SELECT NodeID, 0 AS is_group, 1 AS is_expertise, 0 AS is_favorite, 0 AS is_property
									FROM cn_view_experts AS x
									WHERE vr_expertise_domains = 1 AND ApplicationID = vr_application_id AND UserID = vr_user_id

									UNION ALL

									SELECT nl.node_id, 0 AS is_group, 0 AS is_expertise, 1 AS is_favorite, 0 AS is_property
									FROM cn_node_likes AS nl
										INNER JOIN cn_nodes AS nd
										ON nd.application_id = vr_application_id AND nd.node_id = nl.node_id AND nd.deleted = FALSE
									WHERE vr_favorites = 1 AND nl.application_id = vr_application_id AND 
										nl.user_id = vr_user_id AND nl.deleted = FALSE

									UNION ALL

									SELECT nc.node_id, 0 AS is_group, 0 AS is_expertise, 0 AS is_favorite, 1 AS is_property
									FROM cn_node_creators AS nc
										INNER JOIN cn_nodes AS nd
										ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id AND nd.deleted = FALSE
									WHERE vr_properties = 1 AND nc.application_id = vr_application_id AND 
										nc.user_id = vr_user_id AND nc.deleted = FALSE
								) AS x
							GROUP BY x.node_id
						) AS nodes
						INNER JOIN qa_related_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = nodes.node_id
						INNER JOIN qa_questions AS q
						ON q.application_id = vr_application_id AND q.question_id = nd.question_id AND 
							q.publication_date IS NOT NULL AND q.deleted = FALSE
					WHERE nd.deleted = FALSE

					UNION ALL

					SELECT	q.question_id, 
							q.title,
							q.send_date, 
							q.sender_user_id,
							(CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS has_best_answer,
							q.status,
							NULL AS related_node_id,
							0 AS is_group,
							0 AS is_expertise,
							0 AS is_favorite,
							0 AS is_property,
							1 AS from_friend
					FROM qa_questions AS q
						INNER JOIN usr_view_friends AS f
						ON f.application_id = vr_application_id AND f.user_id = vr_user_id AND 
							f.friend_id = q.sender_user_id AND f.are_friends = TRUE
					WHERE vr_from_friends = 1 AND q.publication_date IS NOT NULL AND q.deleted = FALSE
				) AS qs
			GROUP BY qs.question_id
		) AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_my_favorite_questions;

CREATE PROCEDURE qa_my_favorite_questions
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		questions.*,
		(questions.row_number + questions.rev_row_number - 1) AS total_count,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name,
		(
			SELECT COUNT(r.node_id)
			FROM qa_related_nodes AS r
			WHERE r.application_id = vr_application_id AND 
				r.question_id = questions.question_id AND r.deleted = FALSE
		) AS related_nodes_count,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
			WHERE a.application_id = vr_application_id AND 
				a.question_id = questions.question_id AND a.deleted = FALSE
		) AS answers_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = TRUE
		) AS likes_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = FALSE
		) AS dislikes_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY q.send_date DESC, q.question_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY q.send_date ASC, q.question_id DESC) AS rev_row_number,
					q.question_id, 
					q.title, 
					q.send_date, 
					q.sender_user_id,
					CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
					q.status
			FROM rv_followers AS f
				INNER JOIN qa_questions AS q
				ON f.application_id = vr_application_id AND 
					q.question_id = f.followed_id AND q.deleted = FALSE
			WHERE f.application_id = vr_application_id AND f.user_id = vr_user_id -- AND l.like = TRUE
		) AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_my_asked_questions;

CREATE PROCEDURE qa_my_asked_questions
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		questions.*,
		(questions.row_number + questions.rev_row_number - 1) AS total_count,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name,
		(
			SELECT COUNT(r.node_id)
			FROM qa_related_nodes AS r
			WHERE r.application_id = vr_application_id AND 
				r.question_id = questions.question_id AND r.deleted = FALSE
		) AS related_nodes_count,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
			WHERE a.application_id = vr_application_id AND 
				a.question_id = questions.question_id AND a.deleted = FALSE
		) AS answers_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = TRUE
		) AS likes_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = FALSE
		) AS dislikes_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY q.send_date DESC, q.question_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY q.send_date ASC, q.question_id DESC) AS rev_row_number,
					q.question_id, 
					q.title, 
					q.send_date, 
					q.sender_user_id,
					CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
					q.status
			FROM qa_questions AS q
			WHERE q.sender_user_id = vr_user_id AND q.deleted = FALSE
		) AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_questions_asked_of_me;

CREATE PROCEDURE qa_questions_asked_of_me
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		questions.*,
		(questions.row_number + questions.rev_row_number - 1) AS total_count,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name,
		(
			SELECT COUNT(r.node_id)
			FROM qa_related_nodes AS r
			WHERE r.application_id = vr_application_id AND 
				r.question_id = questions.question_id AND r.deleted = FALSE
		) AS related_nodes_count,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
			WHERE a.application_id = vr_application_id AND 
				a.question_id = questions.question_id AND a.deleted = FALSE
		) AS answers_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = TRUE
		) AS likes_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = FALSE
		) AS dislikes_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY q.send_date DESC, q.question_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY q.send_date ASC, q.question_id DESC) AS rev_row_number,
					q.question_id, 
					q.title, 
					q.send_date, 
					q.sender_user_id,
					CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
					q.status
			FROM qa_related_users AS u
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND 
					q.question_id = u.question_id AND q.deleted = FALSE
			WHERE u.application_id = vr_application_id AND u.user_id = vr_user_id AND u.deleted = FALSE
		) AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_faq_items;

CREATE PROCEDURE qa_get_faq_items
	vr_application_id	UUID,
	vr_category_id		UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		questions.*,
		(questions.row_number + questions.rev_row_number - 1) AS total_count,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name,
		(
			SELECT COUNT(r.node_id)
			FROM qa_related_nodes AS r
			WHERE r.application_id = vr_application_id AND 
				r.question_id = questions.question_id AND r.deleted = FALSE
		) AS related_nodes_count,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
			WHERE a.application_id = vr_application_id AND 
				a.question_id = questions.question_id AND a.deleted = FALSE
		) AS answers_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = TRUE
		) AS likes_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = FALSE
		) AS dislikes_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY i.sequence_number ASC, q.send_date DESC, i.question_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY i.sequence_number DESC, q.send_date ASC, i.question_id DESC) AS rev_row_number,
					q.question_id, 
					q.title, 
					q.send_date, 
					q.sender_user_id,
					CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
					q.status
			FROM qa_faq_items AS i
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = i.question_id AND
					q.publication_date IS NOT NULL AND q.deleted = FALSE
			WHERE i.application_id = vr_application_id AND i.category_id = vr_category_id AND i.deleted = FALSE
		) AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_questions;

CREATE PROCEDURE qa_get_questions
	vr_application_id	UUID,
	vr_searchText	 VARCHAR(1000),
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_searchText IS NULL OR vr_searchText = N'' SET vr_searchText = NULL
	
	IF vr_searchText IS NULL BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
			questions.*,
			(questions.row_number + questions.rev_row_number - 1) AS total_count,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			(
				SELECT COUNT(r.node_id)
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
					r.question_id = questions.question_id AND r.deleted = FALSE
			) AS related_nodes_count,
			(
				SELECT COUNT(a.answer_id)
				FROM qa_answers AS a
				WHERE a.application_id = vr_application_id AND 
					a.question_id = questions.question_id AND a.deleted = FALSE
			) AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = FALSE
			) AS dislikes_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY q.send_date DESC, q.question_id ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY q.send_date ASC, q.question_id DESC) AS rev_row_number,
						q.question_id, 
						q.title, 
						q.send_date, 
						q.sender_user_id,
						CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
						q.status
				FROM qa_questions AS q
				WHERE q.application_id = vr_application_id AND q.deleted = FALSE AND
					q.publication_date IS NOT NULL AND
					(vr_date_from IS NULL OR q.send_date >= vr_date_from) AND
					(vr_date_to IS NULL OR q.send_date <= vr_date_to)
			) AS questions
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
		WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY questions.row_number ASC
	END
	ELSE BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
			questions.*,
			(questions.row_number + questions.rev_row_number - 1) AS total_count,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			(
				SELECT COUNT(r.node_id)
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
					r.question_id = questions.question_id AND r.deleted = FALSE
			) AS related_nodes_count,
			(
				SELECT COUNT(a.answer_id)
				FROM qa_answers AS a
				WHERE a.application_id = vr_application_id AND 
					a.question_id = questions.question_id AND a.deleted = FALSE
			) AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = FALSE
			) AS dislikes_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, srch.key DESC) AS rev_row_number,
						q.question_id, 
						q.title, 
						q.send_date, 
						q.sender_user_id,
						CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
						q.status
				FROM CONTAINSTABLE(qa_questions, (title, description), vr_searchText) AS srch
					INNER JOIN qa_questions AS q
					ON q.application_id = vr_application_id AND q.question_id = srch.key
				WHERE q.deleted = FALSE AND q.publication_date IS NOT NULL AND
					(vr_date_from IS NULL OR q.send_date >= vr_date_from) AND
					(vr_date_to IS NULL OR q.send_date <= vr_date_to)
			) AS questions
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
		WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY questions.row_number ASC
	END
END;


DROP PROCEDURE IF EXISTS qa_find_related_questions;

CREATE PROCEDURE qa_find_related_questions
	vr_application_id	UUID,
	vr_question_id		UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		questions.*,
		(questions.row_number + questions.rev_row_number - 1) AS total_count,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name,
		(
			SELECT COUNT(r.node_id)
			FROM qa_related_nodes AS r
			WHERE r.application_id = vr_application_id AND 
				r.question_id = questions.question_id AND r.deleted = FALSE
		) AS related_nodes_count,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
			WHERE a.application_id = vr_application_id AND 
				a.question_id = questions.question_id AND a.deleted = FALSE
		) AS answers_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = TRUE
		) AS likes_count,
		(
			SELECT COUNT(l.user_id)
			FROM rv_likes AS l
			WHERE l.application_id = vr_application_id AND 
				l.liked_id = questions.question_id AND l.like = FALSE
		) AS dislikes_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY i_ds.count DESC, i_ds.question_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY i_ds.count ASC, i_ds.question_id DESC) AS rev_row_number,
					q.question_id,
					q.title,
					q.send_date,
					q.sender_user_id,
					CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
					q.status
			FROM (
					SELECT r2.question_id, COUNT(r2.node_id) AS count
					FROM qa_related_nodes AS r
						INNER JOIN qa_related_nodes AS r2
						ON r2.application_id = vr_application_id AND 
							r2.node_id = r.node_id AND r2.deleted = FALSE
					WHERE r.application_id = vr_application_id AND 
						r.question_id = vr_question_id AND r.deleted = FALSE
					GROUP BY r2.question_id
				) AS i_ds
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = i_ds.question_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
		) AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_questions_related_to_node;

CREATE PROCEDURE qa_get_questions_related_to_node
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_searchText	 VARCHAR(1000),
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_searchText IS NULL OR vr_searchText = N'' SET vr_searchText = NULL
	
	IF vr_searchText IS NULL BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
			questions.*,
			(questions.row_number + questions.rev_row_number - 1) AS total_count,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			(
				SELECT COUNT(r.node_id)
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
					r.question_id = questions.question_id AND r.deleted = FALSE
			) AS related_nodes_count,
			(
				SELECT COUNT(a.answer_id)
				FROM qa_answers AS a
				WHERE a.application_id = vr_application_id AND 
					a.question_id = questions.question_id AND a.deleted = FALSE
			) AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = FALSE
			) AS dislikes_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY q.send_date DESC, q.question_id ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY q.send_date ASC, q.question_id DESC) AS rev_row_number,
						q.question_id, 
						q.title, 
						q.send_date, 
						q.sender_user_id,
						CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
						q.status
				FROM qa_related_nodes AS r
					INNER JOIN qa_questions AS q
					ON q.application_id = vr_application_id AND 
						q.question_id = r.question_id AND q.deleted = FALSE
				WHERE r.application_id = vr_application_id AND r.node_id = vr_node_id AND 
					r.deleted = FALSE AND q.publication_date IS NOT NULL AND
					(vr_date_from IS NULL OR q.send_date >= vr_date_from) AND
					(vr_date_to IS NULL OR q.send_date <= vr_date_to)
			) AS questions
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
		WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY questions.row_number ASC
	END
	ELSE BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
			questions.*,
			(questions.row_number + questions.rev_row_number - 1) AS total_count,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			(
				SELECT COUNT(r.node_id)
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
					r.question_id = questions.question_id AND r.deleted = FALSE
			) AS related_nodes_count,
			(
				SELECT COUNT(a.answer_id)
				FROM qa_answers AS a
				WHERE a.application_id = vr_application_id AND 
					a.question_id = questions.question_id AND a.deleted = FALSE
			) AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = FALSE
			) AS dislikes_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, srch.key DESC) AS rev_row_number,
						q.question_id, 
						q.title, 
						q.send_date, 
						q.sender_user_id,
						CAST((CASE WHEN q.best_answer_id IS NULL THEN 0 ELSE 1 END) AS boolean) AS has_best_answer,
						q.status
				FROM CONTAINSTABLE(qa_questions, (title, description), vr_searchText) AS srch
					INNER JOIN qa_related_nodes AS r
					INNER JOIN qa_questions AS q
					ON q.application_id = vr_application_id AND 
						q.question_id = r.question_id AND q.deleted = FALSE
					ON r.application_id = vr_application_id AND 
						r.node_id = vr_node_id AND q.question_id = srch.key
				WHERE r.deleted = FALSE AND q.publication_date IS NOT NULL AND
					(vr_date_from IS NULL OR q.send_date >= vr_date_from) AND
					(vr_date_to IS NULL OR q.send_date <= vr_date_to)
			) AS questions
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
		WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY questions.row_number ASC
	END
END;


DROP PROCEDURE IF EXISTS qa_group_questions_by_related_nodes;

CREATE PROCEDURE qa_group_questions_by_related_nodes
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_question_id		UUID,
	vr_searchText	 VARCHAR(1000),
	vr_default_privacy	varchar(50),
	vr_check_access BOOLEAN,
	vr_now		 TIMESTAMP,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_nodes Table (NodeID UUID primary key clustered, count INTEGER)
	
	INSERT INTO vr_nodes (NodeID, count)
	SELECT n.node_id, COUNT(q.question_id)
	FROM qa_related_nodes AS n
		INNER JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = n.question_id AND 
			q.publication_date IS NOT NULL AND q.deleted = FALSE
	WHERE n.application_id = vr_application_id AND n.deleted = FALSE
	GROUP BY n.node_id
	
	IF vr_question_id IS NOT NULL BEGIN
		DELETE vr_nodes
		WHERE NodeID NOT IN (
				SELECT r.node_id
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
						r.question_id = vr_question_id AND r.deleted = FALSE
			)
	END
	
	IF vr_check_access = 1 BEGIN
		DECLARE vr_node_ids KeyLessGuidTableType
	
		INSERT INTO vr_node_ids (Value)
		SELECT NodeID
		FROM vr_nodes
		
		DECLARE	vr_permission_types StringPairTableType
		
		INSERT INTO vr_permission_types (FirstValue, SecondValue)
		VALUES (N'View', vr_default_privacy)
	
		DELETE N
		FROM vr_nodes AS n
			LEFT JOIN prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_node_ids, N'FAQCategory', vr_now, vr_permission_types) AS a
			ON a.id = n.node_id
		WHERE a.id IS NULL
	END
	
	IF vr_searchText IS NULL OR vr_searchText = N'' SET vr_searchText = NULL
	
	IF vr_searchText IS NULL BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
			x.*,
			(x.row_number + x.rev_row_number - 1) AS total_count,
			nd.node_name,
			nd.type_name AS node_type,
			nd.deleted
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY n.count DESC, n.node_id ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY n.count ASC, n.node_id DESC) AS rev_row_number,
						n.node_id,
						n.count
				FROM vr_nodes AS n
			) AS x
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
	ELSE BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
			x.*,
			(x.row_number + x.rev_row_number - 1) AS total_count,
			nd.node_name,
			nd.type_name AS node_type,
			nd.deleted
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, srch.key ASC) AS rev_row_number,
						n.node_id,
						n.count
				FROM CONTAINSTABLE(cn_nodes, (name, additional_id), vr_searchText) AS srch 
					INNER JOIN vr_nodes AS n
					ON srch.key = n.node_id
			) AS x
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
END;


DROP PROCEDURE IF EXISTS qa_find_related_tags;

CREATE PROCEDURE qa_find_related_tags
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT TOP(COALESCE(vr_count, 1000000))
		x.node_id,
		x.questions_count AS count,
		(x.row_number + x.rev_row_number - 1) AS total_count,
		nd.node_name,
		nd.type_name AS node_type,
		nd.deleted
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY tag.count DESC, tag.questions_count DESC, tag.node_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY tag.count ASC, tag.questions_count ASC, tag.node_id DESC) AS rev_row_number,
					tag.*		
			FROM (
					SELECT	i_ds.node_id,
							MAX(i_ds.count) AS count,
							COUNT(q.question_id) AS questions_count
					FROM (
							SELECT r2.node_id, COUNT(r2.question_id) AS count
							FROM qa_related_nodes AS r
								INNER JOIN qa_related_nodes AS r2
								ON r2.application_id = vr_application_id AND 
									r2.question_id = r.question_id AND r2.deleted = FALSE
							WHERE r.application_id = vr_application_id AND 
								r.node_id = vr_node_id AND r.deleted = FALSE
							GROUP BY r2.node_id
						) AS i_ds
						INNER JOIN qa_related_nodes AS r
						ON r.application_id = vr_application_id AND 
							r.node_id = i_ds.node_id AND r.deleted = FALSE
						INNER JOIN qa_questions AS q
						ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
							q.publication_date IS NOT NULL AND q.deleted = FALSE
					GROUP BY i_ds.node_id
				) AS tag
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_check_nodes;

CREATE PROCEDURE qa_check_nodes
	vr_application_id	UUID,
    vr_strNodeIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	SELECT	x.node_id,
			x.questions_count AS count,
			CAST(0 AS bigint) AS total_count,
			nd.node_name,
			nd.type_name AS node_type,
			nd.deleted
	FROM (
			SELECT	i_ds.value AS node_id,
					COUNT(q.question_id) AS questions_count
			FROM vr_node_ids AS i_ds
				LEFT JOIN qa_related_nodes AS r
				ON r.application_id = vr_application_id AND 
					r.node_id = i_ds.value AND r.deleted = FALSE
				LEFT JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
			GROUP BY i_ds.value
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	ORDER BY x.questions_count DESC, x.node_id ASC
END;


DROP PROCEDURE IF EXISTS qa_search_nodes;

CREATE PROCEDURE qa_search_nodes
	vr_application_id	UUID,
    vr_searchText	 VARCHAR(500),
    vr_exactSearch BOOLEAN,
    vr_orderByRank BOOLEAN,
    vr_count		 INTEGER,
    vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE(vr_searchText, N'') = N'' RETURN
	
	IF vr_exactSearch = 1 BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
				x.node_id,
				x.questions_count AS count,
				(x.row_number + x.rev_row_number - 1) AS total_count,
				x.node_name,
				x.node_type,
				x.deleted
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY i_ds.questions_count DESC, i_ds.node_id ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY i_ds.questions_count ASC, i_ds.node_id DESC) AS rev_row_number,
						i_ds.*
				FROM (
						SELECT	nd.node_id,
								COUNT(q.question_id) AS questions_count,
								MAX(nd.node_name) AS node_name,
								MAX(nd.type_name) AS node_type,
								CAST(MAX(CAST(nd.deleted AS integer)) AS boolean) AS deleted
						FROM cn_view_nodes_normal AS nd
							LEFT JOIN qa_related_nodes AS r
							ON r.application_id = vr_application_id AND 
								r.node_id = nd.node_id AND r.deleted = FALSE
							LEFT JOIN qa_questions AS q
							ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
								q.publication_date IS NOT NULL AND q.deleted = FALSE
						WHERE nd.application_id = vr_application_id AND nd.node_name = vr_searchText
						GROUP BY nd.node_id
					) AS i_ds
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
	ELSE BEGIN
		SELECT TOP(COALESCE(vr_count, 1000000))
				x.node_id,
				x.questions_count AS count,
				(x.row_number + x.rev_row_number - 1) AS total_count,
				nd.node_name,
				nd.type_name AS node_type,
				nd.deleted
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY (CASE WHEN vr_orderByRank = 1 THEN i_ds.rank ELSE i_ds.questions_count END) DESC, i_ds.node_id ASC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY (CASE WHEN vr_orderByRank = 1 THEN i_ds.rank ELSE i_ds.questions_count END) ASC, i_ds.node_id DESC) AS rev_row_number,
						i_ds.*
				FROM (
						SELECT	srch.key AS node_id,
								COUNT(q.question_id) AS questions_count,
								MAX(srch.rank) AS rank
						FROM CONTAINSTABLE(cn_nodes, (name), vr_searchText) AS srch
							INNER JOIN cn_view_nodes_normal AS nd
							ON nd.application_id = vr_application_id AND 
								nd.node_id = srch.key AND LEN(nd.node_name) < 25
							LEFT JOIN qa_related_nodes AS r
							ON r.application_id = vr_application_id AND r.node_id = nd.node_id AND r.deleted = FALSE
							LEFT JOIN qa_questions AS q
							ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
								q.publication_date IS NOT NULL AND q.deleted = FALSE
						GROUP BY srch.key
					) AS i_ds
			) AS x
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
END;


DROP PROCEDURE IF EXISTS qa_save_related_nodes;

CREATE PROCEDURE qa_save_related_nodes
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_strNodeIDs		varchar(max),
    vr_delimiter		char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	UPDATE R
		SET Deleted = (CASE WHEN n.value IS NULL THEN 1 ELSE 0 END),
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_node_ids AS n
		RIGHT JOIN qa_related_nodes AS r
		ON r.node_id = n.value
	WHERE r.application_id = vr_application_id AND r.question_id = vr_question_id
			
	INSERT INTO qa_related_nodes (
		ApplicationID, 
		QuestionID, 
		NodeID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, vr_question_id, n.value, vr_current_user_id, vr_now, 0
	FROM vr_node_ids AS n
		LEFT JOIN qa_related_nodes AS r
		ON r.application_id = vr_application_id AND 
			r.question_id = vr_question_id AND r.node_id = n.value
	WHERE r.node_id IS NULL
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS qa_add_related_nodes;

CREATE PROCEDURE qa_add_related_nodes
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_strNodeIDs		varchar(max),
    vr_delimiter		char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	UPDATE R
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_node_ids AS n
		INNER JOIN qa_related_nodes AS r
		ON r.application_id = vr_application_id AND 
			r.node_id = n.value AND r.question_id = vr_question_id
			
	INSERT INTO qa_related_nodes (
		ApplicationID, 
		QuestionID, 
		NodeID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, vr_question_id, n.value, vr_current_user_id, vr_now, 0
	FROM vr_node_ids AS n
		LEFT JOIN qa_related_nodes AS r
		ON r.application_id = vr_application_id AND 
			r.question_id = vr_question_id AND r.node_id = n.value
	WHERE r.node_id IS NULL
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS qa_remove_related_nodes;

CREATE PROCEDURE qa_remove_related_nodes
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_strNodeIDs		varchar(max),
    vr_delimiter		char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	UPDATE R
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_node_ids AS n
		INNER JOIN qa_related_nodes AS r
		ON r.application_id = vr_application_id AND 
			r.node_id = n.value AND r.question_id = vr_question_id
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS qa_is_question_owner;

CREATE PROCEDURE qa_is_question_owner
	vr_application_id				UUID,
    vr_question_idOrAnswerID		UUID,
	vr_user_id						UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) vr_question_idOrAnswerID = COALESCE(QuestionID, vr_question_idOrAnswerID)
	FROM qa_answers
	WHERE ApplicationID = vr_application_id AND AnswerID = vr_question_idOrAnswerID
	
	SELECT
		CASE
			WHEN EXISTS(
				SELECT TOP(1) QuestionID
				FROM qa_questions
				WHERE ApplicationID = vr_application_id AND 
					QuestionID = vr_question_idOrAnswerID AND SenderUserID = vr_user_id
			) THEN 1
			ELSE 0
		END
END;


DROP PROCEDURE IF EXISTS qa_is_answer_owner;

CREATE PROCEDURE qa_is_answer_owner
	vr_application_id	UUID,
    vr_answerID		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		CASE
			WHEN EXISTS(
				SELECT TOP(1) QuestionID
				FROM qa_answers
				WHERE ApplicationID = vr_application_id AND 
					AnswerID = vr_answerID AND SenderUserID = vr_user_id
			) THEN 1
			ELSE 0
		END
END;


DROP PROCEDURE IF EXISTS qa_is_comment_owner;

CREATE PROCEDURE qa_is_comment_owner
	vr_application_id	UUID,
    vr_commentID		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		CASE
			WHEN EXISTS(
				SELECT TOP(1) OwnerID
				FROM qa_comments
				WHERE ApplicationID = vr_application_id AND 
					CommentID = vr_commentID AND SenderUserID = vr_user_id
			) THEN 1
			ELSE 0
		END
END;


DROP PROCEDURE IF EXISTS qa_is_related_user;

CREATE PROCEDURE qa_is_related_user
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		CASE
			WHEN EXISTS(
				SELECT TOP(1) UserID
				FROM qa_related_users
				WHERE ApplicationID = vr_application_id AND 
					UserID = vr_user_id AND QuestionID = vr_question_id AND deleted = FALSE
			) THEN 1
			ELSE 0
		END
END;


DROP PROCEDURE IF EXISTS qa_is_related_expert_or_member;

CREATE PROCEDURE qa_is_related_expert_or_member
	vr_application_id		UUID,
	vr_question_id			UUID,
	vr_user_id				UUID,
	vr_experts		 BOOLEAN,
	vr_members		 BOOLEAN,
	vr_check_candidates BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_experts = COALESCE(vr_experts, 0)
	SET vr_members = COALESCE(vr_members, 0)
	SET vr_check_candidates = COALESCE(vr_check_candidates, 0)

	DECLARE vr_exists BOOLEAN = 0

	IF vr_exists = 0 AND vr_experts = 1 AND vr_check_candidates = 1 BEGIN
		SELECT TOP(1) vr_exists = 1
		FROM qa_questions AS q
			INNER JOIN qa_related_nodes AS rn
			ON q.application_id = vr_application_id AND rn.question_id = q.question_id
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
			INNER JOIN qa_candidate_relations AS cr
			ON cr.application_id = vr_application_id AND 
				(cr.node_id = nd.node_id OR cr.node_type_id = nd.node_type_id) AND cr.deleted = FALSE
			INNER JOIN cn_view_node_members AS nm
			ON nm.application_id = vr_application_id AND 
				nm.node_id = rn.node_id AND nm.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND q.question_id = vr_question_id
	END

	IF vr_exists = 0 AND vr_members = 1 AND vr_check_candidates = 1 BEGIN
		SELECT TOP(1) vr_exists = 1
		FROM qa_questions AS q
			INNER JOIN qa_related_nodes AS rn
			ON q.application_id = vr_application_id AND rn.question_id = q.question_id
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
			INNER JOIN qa_candidate_relations AS cr
			ON cr.application_id = vr_application_id AND 
				(cr.node_id = nd.node_id OR cr.node_type_id = nd.node_type_id) AND cr.deleted = FALSE
			INNER JOIN cn_view_experts AS ex
			ON ex.application_id = vr_application_id AND 
				ex.node_id = rn.node_id AND ex.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND q.question_id = vr_question_id
	END

	IF vr_exists = 0 AND vr_experts = 1 AND vr_check_candidates = 0 BEGIN
		SELECT TOP(1) vr_exists = 1
		FROM qa_related_nodes AS rn
			INNER JOIN cn_view_experts AS ex
			ON ex.application_id = vr_application_id AND 
				ex.node_id = rn.node_id AND ex.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND rn.question_id = QuestionID
	END

	IF vr_exists = 0 AND vr_members = 1 AND vr_check_candidates = 0 BEGIN
		SELECT TOP(1) vr_exists = 1
		FROM qa_related_nodes AS rn
			INNER JOIN cn_view_node_members AS nm
			ON nm.application_id = vr_application_id AND 
				nm.node_id = rn.node_id AND nm.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND rn.question_id = QuestionID
	END

	SELECT vr_exists
END;


DROP PROCEDURE IF EXISTS qa_send_answer;

CREATE PROCEDURE qa_send_answer
	vr_application_id	UUID,
	vr_answerID	 	UUID,
    vr_question_id 	UUID,
    vr_answerBody	 VARCHAR(max),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET vr_answerBody = gfn_verify_string(vr_answerBody)

    INSERT INTO qa_answers (
		application_id,
		answer_id,
        question_id,
        sender_user_id,
        send_date,
        answer_body,
        deleted
    )
    VALUES (
		vr_application_id,
		vr_answerID,
        vr_question_id,
        vr_current_user_id,
        vr_now,
        vr_answerBody,
        0
    )
    
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_edit_answer;

CREATE PROCEDURE qa_edit_answer
	vr_application_id	UUID,
	vr_answerID	 	UUID,
	vr_answerBody	 VARCHAR(max),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET vr_answerBody = gfn_verify_string(vr_answerBody)
	
	UPDATE qa_answers
		SET AnswerBody = vr_answerBody,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND AnswerID = vr_answerID

    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_remove_answer;

CREATE PROCEDURE qa_remove_answer
	vr_application_id	UUID,
	vr_answerID	 	UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE qa_answers
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND AnswerID = vr_answerID

    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_p_get_answers_by_ids;

CREATE PROCEDURE qa_p_get_answers_by_ids
	vr_application_id	UUID,
	vr_answerIDsTemp 	KeyLessGuidTableType readonly,
	vr_current_user_id	UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_answerIDs KeyLessGuidTableType
	INSERT INTO vr_answerIDs (Value) SELECT Value FROM vr_answerIDsTemp

	SELECT	a.answer_id,
			a.question_id,
			a.answer_body,
			a.sender_user_id,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			a.send_date,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = a.answer_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = a.answer_id AND l.like = FALSE
			) AS dislikes_count,
			(
				SELECT TOP(1) l.like
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.user_id = vr_current_user_id AND l.liked_id = a.answer_id
			) AS like_status
	FROM vr_answerIDs AS i_ds
		INNER JOIN qa_answers AS a
		ON a.application_id = vr_application_id AND a.answer_id = i_ds.value
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = a.sender_user_id
	ORDER BY i_ds.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_answers_by_ids;

CREATE PROCEDURE qa_get_answers_by_ids
	vr_application_id	UUID,
	vr_strAnswerIDs	varchar(max),
	vr_delimiter		char,
	vr_current_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_answerIDs KeyLessGuidTableType
	
	INSERT INTO vr_answerIDs (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strAnswerIDs, vr_delimiter) AS ref
	
	EXEC qa_p_get_answers_by_ids vr_application_id, vr_answerIDs, vr_current_user_id
END;


DROP PROCEDURE IF EXISTS qa_get_answers;

CREATE PROCEDURE qa_get_answers
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_current_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_answerIDs KeyLessGuidTableType
	
	INSERT INTO vr_answerIDs (Value)
	SELECT	a.answer_id
	FROM qa_answers AS a
	WHERE a.application_id = vr_application_id AND 
		a.question_id = vr_question_id AND a.deleted = FALSE
	ORDER BY a.send_date ASC, a.answer_id ASC
	
	EXEC qa_p_get_answers_by_ids vr_application_id, vr_answerIDs, vr_current_user_id
END;


DROP PROCEDURE IF EXISTS qa_send_comment;

CREATE PROCEDURE qa_send_comment
	vr_application_id		UUID,
	vr_commentID	 		UUID,
    vr_owner_id	 		UUID,
    vr_reply_to_comment_id	UUID,
    vr_bodyText		 VARCHAR(max),
    vr_current_user_id		UUID,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET vr_bodyText = gfn_verify_string(vr_bodyText)

    INSERT INTO qa_comments (
		application_id,
		comment_id,
        owner_id,
        reply_to_comment_id,
        body_text,
        sender_user_id,
        send_date,
        deleted
    )
    VALUES (
		vr_application_id,
		vr_commentID,
        vr_owner_id,
        vr_reply_to_comment_id,
        vr_bodyText,
        vr_current_user_id,
        vr_now,
        0
    )
    
    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_edit_comment;

CREATE PROCEDURE qa_edit_comment
	vr_application_id	UUID,
	vr_commentID	 	UUID,
	vr_bodyText	 VARCHAR(max),
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET vr_bodyText = gfn_verify_string(vr_bodyText)
	
	UPDATE qa_comments
		SET BodyText = vr_bodyText,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND CommentID = vr_commentID

    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_remove_comment;

CREATE PROCEDURE qa_remove_comment
	vr_application_id	UUID,
	vr_commentID	 	UUID,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE qa_comments
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND CommentID = vr_commentID

    SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS qa_get_comments;

CREATE PROCEDURE qa_get_comments
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_current_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT *
	FROM (
			SELECT	c.comment_id,
					c.owner_id,
					c.reply_to_comment_id,
					c.body_text,
					c.sender_user_id,
					un.username AS sender_username,
					un.first_name AS sender_first_name,
					un.last_name AS sender_last_name,
					c.send_date,
					(
						SELECT COUNT(l.user_id)
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.liked_id = c.comment_id AND l.like = TRUE
					) AS likes_count,
					(
						SELECT TOP(1) l.like
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.user_id = vr_current_user_id AND l.liked_id = c.comment_id
					) AS like_status
			FROM qa_comments AS c
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = c.sender_user_id
			WHERE c.application_id = vr_application_id AND c.owner_id = vr_question_id AND c.deleted = FALSE
			
			UNION ALL
			
			SELECT	c.comment_id,
					c.owner_id,
					c.reply_to_comment_id,
					c.body_text,
					c.sender_user_id,
					un.username AS sender_username,
					un.first_name AS sender_first_name,
					un.last_name AS sender_last_name,
					c.send_date,
					(
						SELECT COUNT(l.user_id)
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.liked_id = c.comment_id AND l.like = TRUE
					) AS likes_count,
					(
						SELECT TOP(1) l.like
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.user_id = vr_current_user_id AND l.liked_id = c.comment_id
					) AS like_status
			FROM qa_answers AS a
				INNER JOIN qa_comments AS c
				ON c.application_id = vr_application_id AND c.owner_id = a.answer_id AND c.deleted = FALSE
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = c.sender_user_id
			WHERE a.application_id = vr_application_id AND a.question_id = vr_question_id AND a.deleted = FALSE
		) AS x
	ORDER BY x.send_date ASC, x.comment_id ASC
END;


DROP PROCEDURE IF EXISTS qa_get_comment_owner_id;

CREATE PROCEDURE qa_get_comment_owner_id
	vr_application_id	UUID,
	vr_commentID	 	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) OwnerID AS id
	FROM qa_comments
	WHERE ApplicationID = vr_application_id AND CommentID = vr_commentID
END;


DROP PROCEDURE IF EXISTS qa_add_knowledgable_user;

CREATE PROCEDURE qa_add_knowledgable_user
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE qa_related_users
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND 
		QuestionID = vr_question_id AND UserID = vr_user_id
		
	IF @vr_rowcount = 0 BEGIN
		INSERT INTO qa_related_users (
			ApplicationID,
			QuestionID,
			UserID,
			SenderUserID,
			SendDate,
			Seen,
			Deleted
		)
		VALUES (
			vr_application_id,
			vr_question_id,
			vr_user_id,
			vr_current_user_id,
			vr_now,
			0,
			0
		)
	END
	
    -- Send new dashboards
    IF vr_user_id IS NOT NULL BEGIN
		DECLARE vr__result INTEGER = 0
    
		EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
			vr_user_id, vr_question_id, NULL, N'Question', N'Knowledgable', 
			vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
    
		DECLARE vr_dashboards DashboardTableType
		
		INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, SubType, Removable, SendDate)
		VALUES (vr_user_id, vr_question_id, vr_question_id, N'Question', N'Knowledgable', 0, vr_now)
		
		EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
		ELSE BEGIN
			SELECT * 
			FROM vr_dashboards
		END
	END
	-- end of send new dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS qa_remove_knowledgable_user;

CREATE PROCEDURE qa_remove_knowledgable_user
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE qa_related_users
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND 
		QuestionID = vr_question_id AND UserID = vr_user_id
	
    -- remove dashboards
    IF vr_user_id IS NOT NULL BEGIN
		DECLARE vr__result INTEGER = 0
    
		EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
			vr_user_id, vr_question_id, NULL, N'Question', N'Knowledgable', 
			vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
		ELSE SELECT 1
	END
	-- end of remove dashboards
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS qa_get_knowledgable_user_ids;

CREATE PROCEDURE qa_get_knowledgable_user_ids
	vr_application_id	UUID,
	vr_question_id	 	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ru.user_id AS id
	FROM qa_related_users AS ru
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.user_id = ru.user_id AND un.is_approved = TRUE
	WHERE ru.application_id = vr_application_id AND 
		ru.question_id = vr_question_id AND ru.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS qa_get_related_expert_and_member_ids;

CREATE PROCEDURE qa_get_related_expert_and_member_ids
	vr_application_id	UUID,
	vr_question_id	 	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT DISTINCT x.id
	FROM (
			SELECT nm.user_id AS id
			FROM qa_related_nodes AS rn
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND 
					nm.node_id = rn.node_id AND nm.is_pending = FALSE
			WHERE rn.application_id = vr_application_id AND 
				rn.question_id = vr_question_id
			
			UNION ALL
			
			SELECT ex.user_id AS id
			FROM qa_related_nodes AS rn
				INNER JOIN cn_view_experts AS ex
				ON ex.application_id = vr_application_id AND ex.node_id = rn.node_id
			WHERE rn.application_id = vr_application_id AND 
				rn.question_id = vr_question_id
		) AS x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.user_id = x.id AND un.is_approved = TRUE
END;


DROP PROCEDURE IF EXISTS qa_find_knowledgeable_user_ids;

CREATE PROCEDURE qa_find_knowledgeable_user_ids
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_senderUserID UUID = (
		SELECT TOP(1) SenderUserID
		FROM qa_questions
		WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
	)
	
	DECLARE vr_users TABLE (
		UserID UUID, 
		Score float, 
		TagScore float, 
		BestAnswerScore float, 
		LikeScore float
	)
		
	;WITH Questions (QuestionID, CommonTagsCount)
 AS 
	(
		SELECT	r2.question_id, 
				COUNT(DISTINCT r2.node_id)
		FROM qa_related_nodes AS r
			INNER JOIN qa_related_nodes AS r2
			ON r2.application_id = vr_application_id AND 
				r2.question_id <> vr_question_id AND r2.node_id = r.node_id AND r2.deleted = FALSE
		WHERE r.application_id = vr_application_id AND 
			r.question_id = vr_question_id AND r.deleted = FALSE
		GROUP BY r2.question_id
	)
	INSERT INTO vr_users (UserID, Score, TagScore, BestAnswerScore, LikeScore)
	SELECT	scores.user_id, 
			SUM(scores.score), 
			SUM(scores.tag_score), 
			SUM(scores.best_answer_score),
			SUM(scores.likes_score)
	FROM (
			SELECT	found.question_id,
					found.user_id,
					(
						(2 * (CAST(found.common_tags_count AS float) / CAST(max_tags.count AS float))) + 
						(1.5 * CAST(found.is_best_answer_sender AS float)) +
						(CAST(found.likes_count AS float) / CAST((CASE WHEN COALESCE(max_likes.count, 0) = 0 THEN 1 ELSE max_likes.count END) AS float))
					) AS score,
					(CAST(found.common_tags_count AS float) / CAST(max_tags.count AS float)) AS tag_score,
					CAST(found.is_best_answer_sender AS float) AS best_answer_score,
					(CAST(found.likes_count AS float) / CAST((CASE WHEN COALESCE(max_likes.count, 0) = 0 THEN 1 ELSE max_likes.count END) AS float)) AS likes_score
			FROM (
					SELECT	qu.question_id,
							qu.user_id,
							MAX(qu.common_tags_count) AS common_tags_count,
							MAX(qu.is_best_answer_sender) AS is_best_answer_sender,
							MAX(qu.likes_count) AS likes_count
					FROM (
						SELECT	a.question_id, 
								questions.common_tags_count,
								a.sender_user_id AS user_id, 
								CAST(1 AS integer) IsBestAnswerSender,
								0 AS likes_count
						FROM Questions
							INNER JOIN qa_questions AS q
							ON q.application_id = vr_application_id AND 
								q.question_id = questions.question_id AND q.best_answer_id IS NOT NULL
							INNER JOIN qa_answers AS a
							ON a.application_id = vr_application_id AND a.answer_id = q.best_answer_id
						
						UNION ALL
						
						SELECT	x.question_id, 
								MAX(x.common_tags_count) AS common_tags_count,
								x.sender_user_id AS user_id, 
								CAST(0 AS integer) IsBestAnswerSender,
								MAX(x.likes_count) AS likes_count
						FROM (
								SELECT	a.question_id, 
										MAX(questions.common_tags_count) AS common_tags_count,
										a.sender_user_id, 
										SUM(
											CASE 
												WHEN l.like IS NULL THEN 0
												WHEN l.like = FALSE THEN -1
												ELSE 1
											END
										) AS likes_count
								FROM Questions
									INNER JOIN qa_answers AS a
									ON a.application_id = vr_application_id AND 
										a.question_id = questions.question_id AND a.deleted = FALSE
									LEFT JOIN rv_likes AS l
									ON l.application_id = vr_application_id AND l.liked_id = a.answer_id
								GROUP BY a.question_id, a.answer_id, a.sender_user_id
							) AS x
						WHERE x.likes_count >= 0
						GROUP BY x.question_id, x.sender_user_id
					) AS qu
					GROUP BY qu.question_id, qu.user_id
				) AS found
				CROSS JOIN (
					SELECT MAX(CommonTagsCount) AS count
					FROM Questions
				) AS max_tags
				LEFT JOIN (
					SELECT	x.question_id, 
							MAX(x.likes_count) AS count
					FROM (
							SELECT	a.question_id, 
									SUM(
										CASE 
											WHEN l.like IS NULL THEN 0
											WHEN l.like = FALSE THEN -1
											ELSE 1
										END
									) AS likes_count
							FROM Questions
								INNER JOIN qa_answers AS a
								ON a.application_id = vr_application_id AND 
									a.question_id = questions.question_id AND a.deleted = FALSE
								LEFT JOIN rv_likes AS l
								ON l.application_id = vr_application_id AND l.liked_id = a.answer_id
							GROUP BY a.question_id, a.answer_id, a.sender_user_id
						) AS x
					WHERE x.likes_count >= 0
					GROUP BY x.question_id
				) AS max_likes
				ON max_likes.question_id = found.question_id
		) AS scores
	GROUP BY scores.user_id
	
	SELECT TOP(COALESCE(vr_count, 1000000))
		(x.row_number + x.rev_row_number - 1) AS total_count,
		x.user_id AS id
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY u.score DESC, u.user_id ASC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY u.score ASC, u.user_id DESC) AS rev_row_number,
					u.*
			FROM vr_users AS u
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND 
					un.user_id = u.user_id AND un.is_approved = TRUE
			WHERE u.user_id <> vr_senderUserID
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
END;


DROP PROCEDURE IF EXISTS qa_get_question_asker_id;

CREATE PROCEDURE qa_get_question_asker_id
	vr_application_id	UUID,
    vr_question_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT SenderUserID
	FROM qa_questions
	WHERE ApplicationID = vr_application_id AND QuestionID = vr_question_id
END;


DROP PROCEDURE IF EXISTS qa_search_questions;

CREATE PROCEDURE qa_search_questions
	vr_application_id	UUID,
    vr_searchText	 VARCHAR(512),
    vr_user_id			UUID,
    vr_count		 INTEGER,
    vr_min_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_verify_string(vr_searchText)
	
	DECLARE vr_temp_ids Table(sqno bigint IDENTITY(1, 1), QuestionID UUID)
	DECLARE vr_question_ids KeyLessGuidTableType
	
	DECLARE vr__st VARCHAR(1000) = vr_searchText
	IF vr_searchText IS NULL OR vr_searchText = N'' SET vr__st = NULL
	
	IF vr__st IS NULL BEGIN
		INSERT INTO vr_temp_ids
		SELECT qu.question_id 
		FROM qa_questions AS qu
		WHERE qu.application_id = vr_application_id AND 
			qu.publication_date IS NOT NULL AND qu.deleted = FALSE
	END
	ELSE BEGIN
		INSERT INTO vr_temp_ids
		SELECT qu.question_id 
		FROM qa_questions AS qu
		WHERE qu.application_id = vr_application_id AND 
			qu.publication_date IS NOT NULL AND qu.deleted = FALSE AND
			CONTAINS((qu.title, qu.description), vr__st)
	END
	
	DECLARE vr_loc bigint = 0
	IF vr_min_id IS NOT NULL 
		SET vr_loc = (SELECT TOP(1) ref.sqno FROM vr_temp_ids AS ref WHERE ref.question_id = vr_min_id)
	IF vr_loc IS NULL SET vr_loc = 0
	
	INSERT INTO vr_question_ids (Value)
	SELECT TOP(vr_count) ref.question_id FROM vr_temp_ids AS ref WHERE ref.sqno > vr_loc
	
	EXEC qa_p_get_questions_by_ids vr_application_id, vr_question_ids, vr_user_id
END;


DROP PROCEDURE IF EXISTS qa_get_questions_count;

CREATE PROCEDURE qa_get_questions_count
	vr_application_id			UUID,
    vr_published			 BOOLEAN,
    vr_creation_dateLowerLimit TIMESTAMP,
    vr_creation_dateUpperLimit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_published IS NULL SET vr_published = 0
	
	SELECT COUNT(*) 
	FROM qa_questions AS q
	WHERE q.application_id = vr_application_id AND
		(vr_creation_dateLowerLimit IS NULL OR q.send_date >= vr_creation_dateLowerLimit) AND
		(vr_creation_dateUpperLimit IS NULL OR q.send_date <= vr_creation_dateUpperLimit) AND
		(vr_published = 0 OR (vr_published = 1 AND q.publication_date IS NOT NULL)) AND 
		q.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS qa_get_answer_sender_ids;

CREATE PROCEDURE qa_get_answer_sender_ids
	vr_application_id	UUID,
    vr_question_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT SenderUserID AS id
	FROM qa_answers
	WHERE ApplicationID = vr_application_id AND 
		QuestionID = vr_question_id AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS qa_get_existing_question_ids;

CREATE PROCEDURE qa_get_existing_question_ids
	vr_application_id	UUID,
	vr_strQuestionIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT QuestionID AS id
	FROM gfn_str_to_guid_table(vr_strQuestionIDs, vr_delimiter) AS i_ds
		INNER JOIN qa_questions AS q
		ON q.question_id = i_ds.value
	WHERE q.application_id = vr_application_id AND q.deleted = FALSE
END;

DROP PROCEDURE IF EXISTS evt_create_event;

CREATE PROCEDURE evt_create_event
	vr_application_id	UUID,
    vr_event_id 		UUID,
    vr_event_type	 VARCHAR(256),
    vr_owner_id		UUID,
    vr_title		 VARCHAR(500),
    vr_description VARCHAR(2000),
    vr_beginDate	 TIMESTAMP,
    vr_finish_date	 TIMESTAMP,
    vr_creator_user_id	UUID,
    vr_creation_date TIMESTAMP,
    vr_strNodeIDs		varchar(8000),
    vr_strUserIDs		varchar(8000),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_description = gfn_verify_string(vr_description)
	
	DECLARE vr_node_ids GuidTableType, vr_user_ids GuidTableType
	
	INSERT INTO vr_node_ids
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strNodeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_user_ids
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strUserIDs, vr_delimiter) AS ref
	WHERE ref.value <> vr_creator_user_id
	
	DECLARE vr__nodes_count INTEGER, vr__users_count INTEGER
	SET vr__nodes_count = (SELECT COUNT(*) FROM vr_node_ids)
	SET vr__users_count = (SELECT COUNT(*) FROM vr_user_ids)
	
	INSERT INTO evt_events(
		ApplicationID,
		EventID,
		EventType,
		OwnerID,
		Title,
		description,
		BeginDate,
		FinishDate,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_event_id,
		vr_event_type,
		vr_owner_id,
		vr_title,
		vr_description,
		vr_beginDate,
		vr_finish_date,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_creator_user_id IS NOT NULL BEGIN
		INSERT INTO evt_related_users(
			ApplicationID,
			EventID,
			UserID,
			status,
			Done,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_event_id,
			vr_creator_user_id,
			N'Accept',
			0,
			0
		)
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr__users_count > 0 BEGIN
		INSERT INTO evt_related_users(
			ApplicationID,
			EventID,
			UserID,
			status,
			Done,
			Deleted
		)
		SELECT vr_application_id, vr_event_id, ref.value, N'Pending', 0, 0
		FROM vr_user_ids AS ref
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr__nodes_count > 0 BEGIN
		INSERT INTO evt_related_nodes(
			ApplicationID,
			EventID,
			NodeID,
			Deleted
		)
		SELECT vr_application_id, vr_event_id, ref.value, 0
		FROM vr_node_ids AS ref
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT (1 + vr__nodes_count + vr__users_count)
COMMIT TRANSACTION;



DROP PROCEDURE IF EXISTS evt_arithmetic_delete_event;

CREATE PROCEDURE evt_arithmetic_delete_event
	vr_application_id	UUID,
	vr_event_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE evt_events
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND EventID = vr_event_id
	
	SELECT @vr_rowcount
END;



DROP PROCEDURE IF EXISTS evt_p_get_events_by_ids;

CREATE PROCEDURE evt_p_get_events_by_ids
	vr_application_id	UUID,
	vr_event_idsTemp	GuidTableType readonly,
	vr_full		 BOOLEAN
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_event_ids GuidTableType
	INSERT INTO vr_event_ids SELECT * FROM vr_event_idsTemp
	
	IF vr_full IS NULL OR vr_full = 0 BEGIN
		SELECT e.event_id AS event_id,
			   e.title AS title
		FROM vr_event_ids AS external_ids
			INNER JOIN evt_events AS e
			ON e.application_id = vr_application_id AND e.event_id = external_ids.value
	END
	ELSE BEGIN
		SELECT e.event_id AS event_id,
			   e.event_type AS event_type,
			   e.title AS title,
			   e.description AS description,
			   e.begin_date AS begin_date,
			   e.finish_date AS finish_date,
			   e.creator_user_id AS creator_user_id
		FROM vr_event_ids AS external_ids
			INNER JOIN evt_events AS e
			ON e.application_id = vr_application_id AND e.event_id = external_ids.value
	END
END;



DROP PROCEDURE IF EXISTS evt_get_events_by_ids;

CREATE PROCEDURE evt_get_events_by_ids
	vr_application_id	UUID,
	vr_strEventIDs	varchar(8000),
	vr_delimiter		char,
	vr_full		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_event_ids GuidTableType
	INSERT INTO vr_event_ids 
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strEventIDs, vr_delimiter) AS ref
	
	EXEC evt_p_get_events_by_ids vr_application_id, vr_event_ids, vr_full
END;


DROP PROCEDURE IF EXISTS evt_get_user_finished_events_count;

CREATE PROCEDURE evt_get_user_finished_events_count
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_current_date TIMESTAMP,
	vr_done		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(ev.event_id)
	FROM evt_related_users AS ru
		INNER JOIN evt_events AS ev
		ON ev.application_id = vr_application_id AND ev.event_id = ru.event_id
	WHERE ru.application_id = vr_application_id AND 
		ru.user_id = vr_user_id AND ev.finish_date <= vr_current_date AND
		(vr_done IS NULL OR ru.done = vr_done) AND ev.deleted = FALSE AND ru.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS evt_get_user_finished_events;

CREATE PROCEDURE evt_get_user_finished_events
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_current_date TIMESTAMP,
	vr_done		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_event_ids GuidTableType
	
	INSERT INTO vr_event_ids
	SELECT e.event_id
	FROM evt_related_users AS ru
		INNER JOIN evt_events AS e
		ON e.application_id = vr_application_id AND
			ru.event_id = e.event_id
	WHERE ru.application_id = vr_application_id AND 
		ru.user_id = vr_user_id AND e.finish_date <= vr_current_date AND
		(vr_done IS NULL OR ru.done = vr_done) AND e.deleted = FALSE AND ru.deleted = FALSE
		
	EXEC evt_p_get_events_by_ids vr_application_id, vr_event_ids, 0
END;


DROP PROCEDURE IF EXISTS evt_get_related_user_ids;

CREATE PROCEDURE evt_get_related_user_ids
	vr_application_id	UUID,
	vr_event_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ru.user_id
	FROM evt_related_users AS ru
	WHERE ru.application_id = vr_application_id AND 
		ru.event_id = vr_event_id AND ru.deleted = FALSE
END;



DROP PROCEDURE IF EXISTS evt_get_related_users;

CREATE PROCEDURE evt_get_related_users
	vr_application_id	UUID,
	vr_event_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ru.user_id AS user_id,
		   ru.event_id AS event_id,
		   ru.status AS status,
		   ru.done AS done,
		   ru.real_finish_date AS real_finish_date,
		   un.username AS username,
		   un.first_name AS first_name,
		   un.last_name AS last_name
	FROM evt_related_users AS ru
		INNER JOIN users_normal AS un 
		ON un.application_id = vr_application_id AND un.user_id = ru.user_id
	WHERE ru.application_id = vr_application_id AND
		ru.event_id = vr_event_id AND ru.deleted = FALSE AND un.is_approved = TRUE
END;



DROP PROCEDURE IF EXISTS evt_arithmetic_delete_related_user;

CREATE PROCEDURE evt_arithmetic_delete_related_user
	vr_application_id	UUID,
	vr_event_id		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__is_own BOOLEAN
	
	SET vr__is_own = (
			SELECT CAST(1 AS boolean) 
			FROM evt_events
			WHERE ApplicationID = vr_application_id AND 
				event_id = vr_event_id AND creator_user_id = vr_user_id
		)
			
	IF vr__is_own IS NULL SET vr__is_own = 0
	
	UPDATE evt_related_users
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND EventID = vr_event_id AND UserID = vr_user_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr__is_own = 1 BEGIN
		UPDATE evt_events
			SET deleted = TRUE
		WHERE ApplicationID = vr_application_id AND event_id = vr_event_id
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
		
		SELECT 2 /* 2: the event is deleted */
	END
	ELSE SELECT 1 /* 1: only the user has been deleted */
COMMIT TRANSACTION;



DROP PROCEDURE IF EXISTS evt_change_user_status;

CREATE PROCEDURE evt_change_user_status
	vr_application_id	UUID,
	vr_event_id		UUID,
	vr_user_id			UUID,
	vr_new_status		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE evt_related_users
		SET Status = vr_new_status
	WHERE ApplicationID = vr_application_id AND EventID = vr_event_id AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;



DROP PROCEDURE IF EXISTS evt_get_related_node_ids;

CREATE PROCEDURE evt_get_related_node_ids
	vr_application_id			UUID,
	vr_event_id				UUID,
	vr_nodeTypeAdditionalID	varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT nd.node_id AS id
	FROM evt_related_nodes AS rn
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
	WHERE rn.application_id = vr_application_id AND rn.event_id = vr_event_id AND 
		(vr_nodeTypeAdditionalID IS NULL OR  nd.type_additional_id = vr_nodeTypeAdditionalID) AND
		rn.deleted = FALSE AND nd.deleted = FALSE
END;



DROP PROCEDURE IF EXISTS evt_get_node_related_events;

CREATE PROCEDURE evt_get_node_related_events
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_current_date TIMESTAMP,
	vr_not_finished BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_event_ids GuidTableType
	
	INSERT INTO vr_event_ids
	SELECT e.event_id
	FROM evt_related_nodes AS rn
		INNER JOIN evt_events AS e
		ON e.application_id = vr_application_id AND e.event_id = rn.event_id
	WHERE rn.application_id = vr_application_id AND rn.node_id = vr_node_id AND 
		(vr_current_date IS NULL OR e.begin_date >= vr_current_date) AND
		(vr_not_finished IS NULL OR vr_not_finished = 0 OR 
		e.begin_date <= vr_current_date) AND e.deleted = FALSE AND rn.deleted = FALSE
		
	EXEC evt_p_get_events_by_ids vr_application_id, vr_event_ids, 0
END;


DROP PROCEDURE IF EXISTS evt_get_user_related_events;

CREATE PROCEDURE evt_get_user_related_events
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_current_date TIMESTAMP,
	vr_not_finished BOOLEAN,
	vr_status			varchar(20),
	vr_node_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ev.event_id AS event_id,
		   ru.user_id AS user_id,
		   ev.event_type AS event_type,
		   ev.title AS title,
		   ev.description AS description,
		   ev.begin_date AS begin_date,
		   ev.finish_date AS finish_date,
		   ev.creator_user_id AS creator_user_id,
		   ru.status AS status,
		   ru.done AS done,
		   ru.real_finish_date AS real_finish_date
	FROM evt_related_users AS ru 
		INNER JOIN evt_events AS ev 
		ON ev.application_id = vr_application_id AND ev.event_id = ru.event_id
	WHERE ru.application_id = vr_application_id AND ru.user_id = vr_user_id AND 
		(vr_current_date IS NULL OR ev.begin_date >= vr_current_date) AND
		(vr_not_finished IS NULL OR vr_not_finished = 0 OR ev.begin_date <= vr_current_date) AND
		(vr_status IS NULL OR ru.status = vr_status) AND
		ev.deleted = FALSE AND ru.deleted = FALSE AND
		(vr_node_id IS NULL OR (
			EXISTS(
					SELECT TOP(1) * 
					FROM evt_related_nodes AS rn2
						INNER JOIN evt_events AS e2
						ON e2.event_id = rn2.event_id
					WHERE rn2.application_id = vr_application_id AND rn2.node_id = vr_node_id
				)
			)
		)
END;

DROP PROCEDURE IF EXISTS srch_get_index_queue_items;

CREATE PROCEDURE srch_get_index_queue_items
	vr_application_id	UUID,
    vr_count		 INTEGER,
	vr_itemType		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_count IS NULL SET vr_count = 10
	IF vr_itemType IS NULL SET vr_itemType = N'Node'

	IF vr_itemType = N'Node' BEGIN
		SELECT TOP(vr_count) 
			nd.node_id AS id,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 
					THEN CAST(1 AS boolean)
				ELSE CAST(0 AS boolean)
			END AS deleted,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nd.node_type_id
			END AS type_id,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nd.type_name
			END AS type,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nd.node_additional_id
			END AS additional_id,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nd.node_name
			END AS title,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nd.description
			END AS description,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE REPLACE(nd.tags, N'~', N' ')
			END AS tags,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE COALESCE(wk_fn_get_wiki_content(vr_application_id, nd.node_id), N'') +  N' ' +
					COALESCE(fg_fn_get_owner_form_contents(vr_application_id, nd.node_id, 3), N'')
			END AS content,
			CASE
				WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE) = 0 OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE cn_fn_get_node_file_contents(vr_application_id, nd.node_id)
			END AS file_content
		FROM cn_view_nodes_normal AS nd
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
		WHERE nd.application_id = vr_application_id
		ORDER BY COALESCE(nd.index_last_update_date, N'1977-01-01 00:00:00.000')
	END
	ELSE IF vr_itemType = N'NodeType' BEGIN
		SELECT TOP(vr_count) 
			nt.node_type_id AS id,
			CASE
				WHEN nt.deleted = TRUE OR COALESCE(s.no_content, FALSE) = 1 THEN CAST(1 AS boolean)
				ELSE CAST(0 AS boolean)
			END AS deleted,
			CASE
				WHEN nt.deleted = TRUE OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nt.name
			END AS title,
			CASE
				WHEN nt.deleted = TRUE OR COALESCE(s.no_content, FALSE) = 1 THEN NULL
				ELSE nt.description
			END AS description
		FROM cn_node_types AS nt
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nt.node_type_id AND s.deleted = FALSE
		WHERE nt.application_id = vr_application_id
		ORDER BY COALESCE(nt.index_last_update_date, N'1977-01-01 00:00:00.000')
	END
	ELSE IF vr_itemType = N'Question' BEGIN
		SELECT TOP(vr_count) 
			qa.question_id AS id,
			qa.deleted AS deleted,
			CASE
				WHEN qa.deleted = TRUE THEN NULL
				ELSE qa.title
			END AS title,
			CASE
				WHEN qa.deleted = TRUE THEN NULL
				ELSE qa.description
			END AS description,
			CASE
				WHEN qa.deleted = TRUE THEN NULL
				ELSE qa_fn_get_question_content(vr_application_id, qa.question_id)
			END AS content
		FROM qa_questions AS qa
		WHERE qa.application_id = vr_application_id
		ORDER BY COALESCE(qa.index_last_update_date, N'1977-01-01 00:00:00.000')
	END
	ELSE IF vr_itemType = N'File' BEGIN
		;WITH X (ID, OwnerID, type, Title, FileContent)
	 AS 
		(
			SELECT TOP(vr_count) 
				fc.file_id AS id,
				af.owner_id,
				af.extension AS type,
				af.file_name AS title,
				fc.content AS file_content
			FROM dct_file_contents AS fc
				INNER JOIN (
					SELECT DISTINCT OwnerID, FileNameGuid, file_name, Extension
					FROM dct_files AS af
					WHERE af.application_id = vr_application_id
				) AS af
				ON af.file_name_guid = fc.file_id
			WHERE fc.application_id = vr_application_id AND 
				fc.not_extractable = 0 AND fc.file_not_found = 0
			ORDER BY COALESCE(fc.index_last_update_date, N'1977-01-01 00:00:00.000')
		)
		(
			SELECT	x.id,
					CAST(b.deleted AS boolean) AS deleted,
					CASE WHEN b.deleted = TRUE THEN NULL ELSE x.type END AS type,
					CASE WHEN b.deleted = TRUE THEN NULL ELSE x.title END AS title,
					CASE WHEN b.deleted = TRUE THEN NULL ELSE x.file_content END AS file_content
			FROM X
				LEFT JOIN (
					SELECT a.id, MAX(a.type) AS type, MAX(a.title) AS title, 
						MAX(a.file_content) AS file_content, MIN(a.deleted) AS deleted
					FROM (
							SELECT x.id, x.type, x.title, x.file_content, nd.deleted
							FROM X
								INNER JOIN cn_nodes AS nd
								ON nd.application_id = vr_application_id AND nd.node_id = x.owner_id
								
							UNION ALL
							
							SELECT x.id, x.type, x.title, x.file_content,
								(CASE WHEN e.deleted = TRUE OR i.deleted = TRUE OR nd.deleted = TRUE THEN 1 ELSE 0 END)
							FROM X
								INNER JOIN fg_instance_elements AS e
								ON e.application_id = vr_application_id AND e.element_id = x.owner_id
								INNER JOIN fg_form_instances AS i
								ON i.application_id = vr_application_id AND i.instance_id = e.instance_id
								INNER JOIN cn_nodes AS nd
								ON nd.application_id = vr_application_id AND nd.node_id = i.owner_id
						) A
					GROUP BY a.id
				) AS b
				ON b.id = x.id
		)
	END
	ELSE IF vr_itemType = N'User' BEGIN
		SELECT TOP(vr_count) 
			un.user_id AS id,
			CASE
				WHEN un.is_approved = TRUE THEN CAST(0 AS boolean)
				ELSE CAST(1 AS boolean)
			END AS deleted,
			un.username AS additional_id,
			COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'') AS title
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id
		ORDER BY COALESCE(un.index_last_update_date, N'1977-01-01 00:00:00.000')
	END
END;


DROP PROCEDURE IF EXISTS srch_set_index_last_update_date;

CREATE PROCEDURE srch_set_index_last_update_date
	vr_application_id	UUID,
	vr_itemType		varchar(20),
	vr_strIDs			varchar(max),
	vr_delimiter		char,
	vr_date		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs GuidTableType
	INSERT INTO vr_iDs
	SELECT DISTINCT * FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter)
	
	IF vr_itemType = N'Node' BEGIN
		UPDATE Ref
			SET IndexLastUpdateDate = vr_date
		FROM vr_iDs AS i_ds
			INNER JOIN cn_nodes AS ref
			ON ref.application_id = vr_application_id AND ref.node_id = i_ds.value
	END
	ELSE IF vr_itemType = N'NodeType' BEGIN
		UPDATE Ref
			SET IndexLastUpdateDate = vr_date
		FROM vr_iDs AS i_ds
			INNER JOIN cn_node_types AS ref
			ON ref.application_id = vr_application_id AND ref.node_type_id = i_ds.value
	END
	ELSE IF vr_itemType = N'Question' BEGIN
		UPDATE Ref
			SET IndexLastUpdateDate = vr_date
		FROM vr_iDs AS i_ds
			INNER JOIN qa_questions AS ref
			ON ref.application_id = vr_application_id AND ref.question_id = i_ds.value
	END
	ELSE IF vr_itemType = N'File' BEGIN
		UPDATE Ref
			SET IndexLastUpdateDate = vr_date
		FROM vr_iDs AS i_ds
			INNER JOIN dct_file_contents AS ref
			ON ref.application_id = vr_application_id AND ref.file_id = i_ds.value
	END
	ELSE IF vr_itemType = N'User' BEGIN
		UPDATE Ref
			SET IndexLastUpdateDate = vr_date
		FROM vr_iDs AS i_ds
			INNER JOIN usr_profile AS ref
			ON ref.user_id = i_ds.value
	END
	
	SELECT @vr_rowcount
END;




DROP PROCEDURE IF EXISTS wk_p_send_dashboards;

CREATE PROCEDURE wk_p_send_dashboards
	vr_application_id		UUID,
	vr_ref_item_id			UUID,
	vr_node_id				UUID,
	vr_adminUserIDsTemp	GuidTableType readonly,
	vr_sendDate		 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_adminUserIDs GuidTableType
	INSERT INTO vr_adminUserIDs SELECT * FROM vr_adminUserIDsTemp
	
	IF (SELECT COUNT(*) FROM vr_adminUserIDs) = 0 BEGIN
		SET vr__result = 1
		RETURN
	END
	
	DECLARE vr_u_ids TABLE(UserID UUID primary key clustered, exists BOOLEAN)
	
	INSERT INTO vr_u_ids (UserID, exists)
	SELECT a.value, MAX(CASE WHEN d.id IS NULL THEN 0 ELSE 1 END)
	FROM vr_adminUserIDs AS a
		LEFT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = a.value AND 
			d.node_id = vr_node_id AND d.type = N'Wiki' AND d.deleted = FALSE AND d.done = FALSE
	GROUP BY a.value
		
	IF EXISTS(SELECT TOP(1) * FROM vr_u_ids WHERE exists = TRUE) BEGIN
		UPDATE ntfn_dashboards
			SET Seen = 0
		FROM vr_u_ids AS u_ids
			INNER JOIN ntfn_dashboards AS d
			ON d.user_id = u_ids.user_id
		WHERE d.application_id = vr_application_id AND uids.exists = TRUE AND 
			d.node_id = vr_node_id AND d.type = N'Wiki' AND d.done = FALSE AND d.deleted = FALSE
			
		SET vr__result = @vr_rowcount
		IF vr__result <= 0 RETURN
	END
	
	IF EXISTS(SELECT TOP(1) * FROM vr_u_ids WHERE exists = FALSE) BEGIN
		DECLARE vr_dashboards DashboardTableType
		
		INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, Removable, SendDate)
		SELECT	u_ids.user_id, vr_node_id, vr_ref_item_id, N'Wiki', 1, vr_sendDate
		FROM vr_u_ids AS u_ids
		WHERE u_ids.exists = FALSE
		
		EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
		
		IF vr__result <= 0 RETURN
		
		IF vr__result > 0 BEGIN
			SELECT * 
			FROM vr_dashboards
		END
	END
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS wk_set_titles_order;

CREATE PROCEDURE wk_set_titles_order
	vr_application_id	UUID,
	vr_strTitleIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_titleIDs TABLE (SequenceNo INTEGER identity(1, 1) primary key, TitleID UUID)
	
	INSERT INTO vr_titleIDs (TitleID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strTitleIDs, vr_delimiter) AS ref
	
	DECLARE vr_owner_id UUID
	
	SELECT vr_owner_id = OwnerID
	FROM wk_titles
	WHERE ApplicationID = vr_application_id AND 
		TitleID = (SELECT TOP (1) ref.title_id FROM vr_titleIDs AS ref)
	
	IF vr_owner_id IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO vr_titleIDs (TitleID)
	SELECT tt.title_id
	FROM vr_titleIDs AS ref
		RIGHT JOIN wk_titles AS tt
		ON tt.title_id = ref.title_id
	WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id AND ref.title_id IS NULL
	ORDER BY tt.sequence_no
	
	UPDATE wk_titles
		SET SequenceNo = ref.sequence_no
	FROM vr_titleIDs AS ref
		INNER JOIN wk_titles AS tt
		ON tt.title_id = ref.title_id
	WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_set_paragraphs_order;

CREATE PROCEDURE wk_set_paragraphs_order
	vr_application_id		UUID,
	vr_strParagraphIDs	varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_paragraph_ids TABLE (SequenceNo INTEGER identity(1, 1) primary key, ParagraphID UUID)
	
	INSERT INTO vr_paragraph_ids (ParagraphID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strParagraphIDs, vr_delimiter) AS ref
	
	DECLARE vr_titleID UUID
	
	SELECT vr_titleID = TitleID
	FROM wk_paragraphs
	WHERE ApplicationID = vr_application_id AND 
		ParagraphID = (SELECT TOP (1) ref.paragraph_id FROM vr_paragraph_ids AS ref)
	
	IF vr_titleID IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO vr_paragraph_ids(ParagraphID)
	SELECT p.paragraph_id
	FROM vr_paragraph_ids AS ref
		RIGHT JOIN wk_paragraphs AS p
		ON p.paragraph_id = ref.paragraph_id
	WHERE p.application_id = vr_application_id AND p.title_id = vr_titleID AND ref.paragraph_id IS NULL
	ORDER BY p.sequence_no
	
	UPDATE wk_paragraphs
		SET SequenceNo = ref.sequence_no
	FROM vr_paragraph_ids AS ref
		INNER JOIN wk_paragraphs AS p
		ON p.paragraph_id = ref.paragraph_id
	WHERE p.application_id = vr_application_id AND p.title_id = vr_titleID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_p_add_title;

CREATE PROCEDURE wk_p_add_title
	vr_application_id		UUID,
    vr_titleID	 		UUID,
    vr_owner_id			UUID,
    vr_title			 VARCHAR(500),
    vr_sequenceNo		 INTEGER,
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP,
    vr_owner_type			varchar(20),
    vr_accept			 BOOLEAN,
    vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(LTRIM(RTRIM(vr_title)))
	
	IF COALESCE(vr_title, N'') = N'' BEGIN
		SET vr__result = -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr_status varchar(20)
	
	IF vr_accept = 1 SET vr_status = N'Accepted'
	ELSE SET vr_status = N'CitationNeeded'
	
	-- Update All Sequence Numbers
	UPDATE TT
		SET SequenceNo = ref.sequence_no
	FROM (
			SELECT	t.title_id,
					((ROW_NUMBER() OVER (ORDER BY t.deleted ASC, t.sequence_no ASC)) * 2) AS sequence_no
			FROM wk_titles AS t
			WHERE t.application_id = vr_application_id AND t.owner_id = vr_owner_id
		) AS ref
		INNER JOIN wk_titles AS tt
		ON tt.application_id = vr_application_id AND tt.title_id = ref.title_id
		
	IF COALESCE(vr_sequenceNo, 0) <= 0 SET vr_sequenceNo = 1
	
	SET vr_sequenceNo = (vr_sequenceNo * 2) - 1
	-- end of Update All Sequence Numbers
	
	INSERT INTO wk_titles(
		ApplicationID,
		TitleID,
		OwnerID,
		CreatorUserID,
		CreationDate,
		SequenceNo,
		Title,
		status,
		OwnerType,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_titleID,
		vr_owner_id,
		vr_creator_user_id,
		vr_creation_date,
		vr_sequenceNo,
		vr_title,
		vr_status,
		vr_owner_type,
		0
	)
	
	SET vr__result = 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wk_add_title;

CREATE PROCEDURE wk_add_title
	vr_application_id		UUID,
    vr_titleID	 		UUID,
    vr_owner_id			UUID,
    vr_title			 VARCHAR(500),
    vr_sequenceNo		 INTEGER,
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP,
    vr_owner_type			varchar(20),
    vr_accept			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER = -1
	
	EXEC wk_p_add_title vr_application_id, vr_titleID, vr_owner_id, vr_title, 
		vr_sequenceNo, vr_creator_user_id, vr_creation_date, vr_owner_type, vr_accept, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS wk_modify_title;

CREATE PROCEDURE wk_modify_title
	vr_application_id			UUID,
    vr_titleID 				UUID,
    vr_title				 VARCHAR(500),
    vr_last_modifier_user_id		UUID,
    vr_last_modification_date TIMESTAMP,
    vr_accept				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(LTRIM(RTRIM(vr_title)))
	
	IF COALESCE(vr_title, N'') = N'' BEGIN
		SELECT -1
		RETURN
	END
	
	DECLARE vr_status varchar(20)
	
	IF vr_accept = 1 SET vr_status = N'Accepted'
	ELSE SET vr_status = N'CitationNeeded'
	
	UPDATE wk_titles
		SET Title = vr_title,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
			status = vr_status
	WHERE ApplicationID = vr_application_id AND TitleID = vr_titleID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_arithmetic_delete_title;

CREATE PROCEDURE wk_arithmetic_delete_title
	vr_application_id			UUID,
	vr_titleID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_titles
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND TitleID = vr_titleID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_recycle_title;

CREATE PROCEDURE wk_recycle_title
	vr_application_id			UUID,
	vr_titleID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_titles
		SET deleted = FALSE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND TitleID = vr_titleID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_p_add_paragraph;

CREATE PROCEDURE wk_p_add_paragraph
	vr_application_id		UUID,
    vr_paragraph_id 		UUID,
    vr_titleID	 		UUID,
    vr_title			 VARCHAR(500),
    vr_bodyText		 VARCHAR(max),
    vr_sequenceNo		 INTEGER,
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP,
    vr_isRichText		 BOOLEAN,
    vr_sendToAdmins	 BOOLEAN,
    vr_has_admin		 BOOLEAN,
    vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_bodyText = gfn_verify_string(vr_bodyText)
	
	IF vr_has_admin IS NULL SET vr_has_admin = 0
	
	DECLARE vr_status varchar(20)
	
	IF vr_sendToAdmins IS NULL OR vr_sendToAdmins = 0 SET vr_status = N'Accepted'
	ELSE IF vr_has_admin = 0 SET vr_status = N'CitationNeeded'
	ELSE SET vr_status = N'Pending'
	
	-- Update All Sequence Numbers
	UPDATE P
		SET SequenceNo = ref.sequence_no
	FROM (
			SELECT	p.paragraph_id,
					((ROW_NUMBER() OVER (ORDER BY p.deleted ASC, p.sequence_no ASC)) * 2) AS sequence_no
			FROM wk_paragraphs AS p
			WHERE p.application_id = vr_application_id AND p.title_id = vr_titleID
		) AS ref
		INNER JOIN wk_paragraphs AS p
		ON p.application_id = vr_application_id AND p.paragraph_id = ref.paragraph_id
		
	IF COALESCE(vr_sequenceNo, 0) <= 0 SET vr_sequenceNo = 1
	
	SET vr_sequenceNo = (vr_sequenceNo * 2) - 1
	-- end of Update All Sequence Numbers
	
	INSERT INTO wk_paragraphs(
		ApplicationID,
		ParagraphID,
		TitleID,
		CreatorUserID,
		CreationDate,
		Title,
		BodyText,
		SequenceNo,
		IsRichText,
		status,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_paragraph_id,
		vr_titleID,
		vr_creator_user_id,
		vr_creation_date,
		vr_title,
		vr_bodyText,
		vr_sequenceNo,
		vr_isRichText,
		vr_status,
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SET vr__result = -1
		RETURN
	END
	
	DECLARE vr__change_id UUID = gen_random_uuid()
	
	INSERT INTO wk_changes(
		ApplicationID,
		ChangeID,
		ParagraphID,
		UserID,
		SendDate,
		Title,
		BodyText,
		Applied,
		status,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr__change_id,
		vr_paragraph_id,
		vr_creator_user_id,
		vr_creation_date,
		vr_title,
		vr_bodyText,
		(CASE WHEN vr_status = N'CitationNeeded' OR vr_status = N'Accepted' THEN 1 ELSE 0 END),
		(CASE WHEN vr_status = N'CitationNeeded' OR vr_status = N'Accepted' THEN N'Accepted' ELSE N'Pending' END),
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SET vr__result = -1
		RETURN
	END
	
	SET vr__result = 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wk_add_paragraph;

CREATE PROCEDURE wk_add_paragraph
	vr_application_id		UUID,
    vr_paragraph_id 		UUID,
    vr_titleID	 		UUID,
    vr_title			 VARCHAR(500),
    vr_bodyText		 VARCHAR(max),
    vr_sequenceNo		 INTEGER,
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP,
    vr_isRichText		 BOOLEAN,
    vr_sendToAdmins	 BOOLEAN,
    vr_has_admin		 BOOLEAN,
    vr_adminUserIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_adminUserIDs GuidTableType
	INSERT INTO vr_adminUserIDs SELECT * FROM vr_adminUserIDsTemp
	
	DECLARE vr__result INTEGER = -1
	
	EXEC wk_p_add_paragraph vr_application_id, vr_paragraph_id, vr_titleID, vr_title, vr_bodyText,
		vr_sequenceNo, vr_creator_user_id, vr_creation_date, vr_isRichText, vr_sendToAdmins, 
		vr_has_admin, vr__result output
	
	-- Send Dashboards
	DECLARE vr_u_ids GuidTableType
	
	INSERT INTO vr_u_ids
	SELECT ref.value
	FROM vr_adminUserIDs AS ref
	WHERE ref.value <> vr_creator_user_id
	
	IF vr_sendToAdmins = 1 AND (SELECT COUNT(*) FROM vr_u_ids) > 0 BEGIN
		DECLARE vr_owner_id UUID = (
			SELECT TOP(1) OwnerID
			FROM wk_titles
			WHERE ApplicationID = vr_application_id AND TitleID = vr_titleID
		)
		
		EXEC wk_p_send_dashboards vr_application_id, vr_paragraph_id, vr_owner_id, vr_u_ids, 
			vr_creation_date, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION 
			RETURN
		END
	END
	-- end of Send Dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wk_modify_paragraph;

CREATE PROCEDURE wk_modify_paragraph
	vr_application_id			UUID,
    vr_paragraph_id			UUID,
    vr_change_id2_accept		UUID,
    vr_title				 VARCHAR(500),
    vr_bodyText			 VARCHAR(max),
    vr_last_modifier_user_id		UUID,
    vr_last_modification_date TIMESTAMP,
    vr_citation_needed		 BOOLEAN,
    vr_apply				 BOOLEAN,
    vr_accept				 BOOLEAN,
    vr_has_admin			 BOOLEAN,
    vr_adminUserIDsTemp		GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_adminUserIDs GuidTableType
	INSERT INTO vr_adminUserIDs SELECT * FROM vr_adminUserIDsTemp
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_bodyText = gfn_verify_string(vr_bodyText)
	
	IF vr_has_admin IS NULL SET vr_has_admin = 0
	
	DECLARE vr_acceptionDate TIMESTAMP, vr_applied BOOLEAN, vr_change_status varchar(20)
	
	SET vr_acceptionDate = NULL
	IF vr_accept = 1 SET vr_acceptionDate = vr_last_modification_date
	
	SET vr_applied = 0
	IF vr_apply = 1 SET vr_applied = 1
	
	SET vr_change_status = N'Pending'
	IF vr_apply = 1 SET vr_change_status = N'Accepted'
	
	DECLARE vr__change_id UUID = (
		SELECT TOP(1) ChangeID 
		FROM wk_changes
		WHERE ApplicationID = vr_application_id AND ParagraphID = vr_paragraph_id 
			AND UserID = vr_last_modifier_user_id AND status = N'Pending' AND deleted = FALSE
	)
	
	IF vr__change_id IS NOT NULL BEGIN	
		UPDATE wk_changes
			SET Title = vr_title,
				BodyText = vr_bodyText,
				LastModificationDate = vr_last_modification_date,
				status = vr_change_status
		WHERE ApplicationID = vr_application_id AND ChangeID = vr__change_id
	END
	ELSE BEGIN
		SET vr__change_id = gen_random_uuid()
	
		INSERT INTO wk_changes(
			ApplicationID,
			ChangeID,
			ParagraphID,
			UserID,
			SendDate,
			Title,
			BodyText,
			Applied,
			ApplicationDate,
			status,
			AcceptionDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr__change_id,
			vr_paragraph_id,
			vr_last_modifier_user_id,
			vr_last_modification_date,
			vr_title,
			vr_bodyText,
			vr_applied,
			vr_last_modification_date,
			vr_change_status,
			vr_acceptionDate,
			0
		)
	END
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_apply = 1 BEGIN
		DECLARE vr__result INTEGER
	
		IF vr_change_id2_accept IS NOT NULL BEGIN
			EXEC wk_p_accept_change vr_application_id, vr_change_id2_accept, 
				vr_last_modifier_user_id, vr_last_modification_date, vr__result output
				
			IF vr__result <= 0 BEGIN
				SELECT -1
				ROLLBACK TRANSACTION 
				RETURN
			END
		END
	
		DECLARE vr_subjectStatus varchar(20)
		SET vr_subjectStatus = N'Accepted'
		IF vr_citation_needed = 1 SET vr_subjectStatus = N'CitationNeeded'
		
		UPDATE wk_paragraphs
			SET Title = vr_title,
				BodyText = vr_bodyText,
				LastModifierUserID = vr_last_modifier_user_id,
				LastModificationDate = vr_last_modification_date,
				status = vr_subjectStatus
		WHERE ApplicationID = vr_application_id AND ParagraphID = vr_paragraph_id
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	-- Send Dashboards
	DECLARE vr_u_ids GuidTableType
	
	INSERT INTO vr_u_ids
	SELECT ref.value
	FROM vr_adminUserIDs AS ref
	WHERE ref.value <> vr_last_modifier_user_id
	
	IF COALESCE(vr_apply, 0) = 0 AND vr_has_admin = 1 AND (SELECT COUNT(*) FROM vr_u_ids) > 0 BEGIN
		DECLARE vr_owner_id UUID = (
			SELECT TOP(1) OwnerID
			FROM wk_paragraphs AS p
				INNER JOIN wk_titles AS t
				ON t.application_id = vr_application_id AND t.title_id = p.title_id
			WHERE p.application_id = vr_application_id AND p.paragraph_id = vr_paragraph_id
		)
		
		EXEC wk_p_send_dashboards vr_application_id, vr_paragraph_id, vr_owner_id, vr_u_ids, 
			vr_last_modification_date, vr__result output
		
		IF vr__result <= 0 BEGIN
			SET vr__result = -1
			ROLLBACK TRANSACTION 
			RETURN
		END
	END
	-- end of Send Dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wk_arithmetic_delete_paragraph;

CREATE PROCEDURE wk_arithmetic_delete_paragraph
	vr_application_id			UUID,
	vr_paragraph_id			UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_paragraphs
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND ParagraphID = vr_paragraph_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_recycle_paragraph;

CREATE PROCEDURE wk_recycle_paragraph
	vr_application_id			UUID,
	vr_paragraph_id			UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_paragraphs
		SET deleted = FALSE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND ParagraphID = vr_paragraph_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_p_accept_change;

CREATE PROCEDURE wk_p_accept_change
	vr_application_id		UUID,
	vr_change_id			UUID,
	vr_evaluator_user_id	UUID,
	vr_evaluation_date	 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_changes
		SET status = N'Accepted',
			acception_date = vr_evaluation_date,
			evaluator_user_id = vr_evaluator_user_id,
			evaluation_date = vr_evaluation_date
	WHERE ApplicationID = vr_application_id AND ChangeID = vr_change_id
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_accept_change;

CREATE PROCEDURE wk_accept_change
	vr_application_id		UUID,
	vr_change_id			UUID,
	vr_evaluator_user_id	UUID,
	vr_evaluation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC wk_p_accept_change vr_application_id, vr_change_id, 
		vr_evaluator_user_id, vr_evaluation_date, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS wk_reject_change;

CREATE PROCEDURE wk_reject_change
	vr_application_id		UUID,
	vr_change_id			UUID,
	vr_evaluator_user_id	UUID,
	vr_evaluation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_changes
		SET status = N'Rejected',
			evaluator_user_id = vr_evaluator_user_id,
			evaluation_date = vr_evaluation_date
	WHERE ApplicationID = vr_application_id AND ChangeID = vr_change_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_arithmetic_delete_change;

CREATE PROCEDURE wk_arithmetic_delete_change
	vr_application_id	UUID,
	vr_change_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wk_changes
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ChangeID = vr_change_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wk_p_get_titles_by_ids;

CREATE PROCEDURE wk_p_get_titles_by_ids
	vr_application_id	UUID,
	vr_titleIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_titleIDs GuidTableType
	INSERT INTO vr_titleIDs SELECT * FROM vr_titleIDsTemp
	
	SELECT tt.title_id AS title_id,
		   tt.owner_id AS owner_id,
		   tt.title AS title,
		   tt.sequence_no AS sequence_number,
		   tt.creator_user_id AS creator_user_id,
		   tt.creation_date AS creation_date,
		   tt.last_modification_date AS last_modification_date,
		   tt.status AS status
	FROM vr_titleIDs AS external_ids
		INNER JOIN wk_titles AS tt
		ON tt.application_id = vr_application_id AND external_ids.value = tt.title_id
	ORDER BY tt.sequence_no
END;


DROP PROCEDURE IF EXISTS wk_get_titles_by_ids;

CREATE PROCEDURE wk_get_titles_by_ids
	vr_application_id	UUID,
	vr_strTitleIDs	varchar(max),
	vr_delimiter		char,
	vr_viewer_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_titleIDs GuidTableType
	INSERT INTO vr_titleIDs
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strTitleIDs, vr_delimiter) AS ref
	
	EXEC wk_p_get_titles_by_ids vr_application_id, vr_titleIDs
END;


DROP PROCEDURE IF EXISTS wk_get_titles;

CREATE PROCEDURE wk_get_titles
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_isAdmin	 BOOLEAN,
	vr_viewer_user_id	UUID,
	vr_deleted	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_isAdmin IS NULL SET vr_isAdmin = 0
	IF vr_deleted IS NULL SET vr_deleted = 0
	
	DECLARE vr_titleIDs GuidTableType
	
	INSERT INTO vr_titleIDs
	SELECT t.title_id
	FROM wk_titles AS t
		LEFT JOIN wk_paragraphs AS p
		ON p.application_id = vr_application_id AND p.title_id = t.title_id AND (
			vr_isAdmin = 1 OR p.status = N'Accepted' OR p.status = N'CitationNeeded' OR (
				p.status = N'Pending' AND vr_viewer_user_id IS NOT NULL AND 
				p.creator_user_id = vr_viewer_user_id
			)
		) AND p.deleted = vr_deleted
	WHERE t.application_id = vr_application_id AND t.owner_id = vr_owner_id AND (
			vr_isAdmin = 1 OR t.status = N'Accepted' OR (
				t.status = N'CitationNeeded' AND vr_viewer_user_id IS NOT NULL AND 
				t.creator_user_id = vr_viewer_user_id
			) OR p.paragraph_id IS NOT NULL
		) AND t.deleted = vr_deleted
	GROUP BY t.title_id
	
	EXEC wk_p_get_titles_by_ids vr_application_id, vr_titleIDs
END;


DROP PROCEDURE IF EXISTS wk_has_title;

CREATE PROCEDURE wk_has_title
	vr_application_id		UUID,
	vr_owner_id			UUID,
	vr_viewer_user_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) 1
	FROM wk_titles AS t
	WHERE t.application_id = vr_application_id AND t.owner_id = vr_owner_id AND
		(vr_viewer_user_id IS NULL OR t.status = N'Accepted' OR 
		t.status = N'CitationNeeded' OR t.creator_user_id = vr_viewer_user_id) AND t.deleted = FALSE
	
	SELECT -1
END;


DROP PROCEDURE IF EXISTS wk_p_get_paragraphs_by_ids;

CREATE PROCEDURE wk_p_get_paragraphs_by_ids
	vr_application_id		UUID,
	vr_paragraph_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_paragraph_ids GuidTableType
	INSERT INTO vr_paragraph_ids SELECT * FROM vr_paragraph_idsTemp
	
	SELECT pg.paragraph_id AS paragraph_id,
		   pg.title_id AS title_id,
		   pg.title AS title,
		   pg.body_text AS body_text,
		   pg.sequence_no AS sequence_number,
		   pg.is_rich_text AS is_rich_text,
		   pg.creator_user_id AS creator_user_id,
		   pg.creation_date AS creation_date,
		   pg.last_modification_date AS last_modification_date,
		   pg.status AS status
	FROM vr_paragraph_ids AS external_ids
		INNER JOIN wk_paragraphs AS pg
		ON pg.application_id = vr_application_id AND pg.paragraph_id = external_ids.value
END;


DROP PROCEDURE IF EXISTS wk_get_paragraphs_by_ids;

CREATE PROCEDURE wk_get_paragraphs_by_ids
	vr_application_id		UUID,
	vr_strParagraphIDs	varchar(max),
	vr_delimiter			char,
	vr_viewer_user_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_paragraph_ids GuidTableType
	INSERT INTO vr_paragraph_ids
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strParagraphIDs, vr_delimiter) AS ref
	
	EXEC wk_p_get_paragraphs_by_ids vr_application_id, vr_paragraph_ids
END;


DROP PROCEDURE IF EXISTS wk_get_paragraphs;

CREATE PROCEDURE wk_get_paragraphs
	vr_application_id		UUID,
	vr_strTitleIDs		varchar(max),
	vr_delimiter			char,
	vr_isAdmin		 BOOLEAN,
	vr_viewer_user_id		UUID,
	vr_deleted		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_isAdmin IS NULL SET vr_isAdmin = 0
	IF vr_deleted IS NULL SET vr_deleted = 0
	
	DECLARE vr_titleIDs GuidTableType
	INSERT INTO vr_titleIDs
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strTitleIDs, vr_delimiter) AS ref
	
	DECLARE vr_paragraph_ids GuidTableType
	
	INSERT INTO vr_paragraph_ids
	SELECT pg.paragraph_id
	FROM vr_titleIDs AS external_ids
		INNER JOIN wk_paragraphs AS pg
		ON pg.title_id = external_ids.value
	WHERE pg.application_id = vr_application_id AND 
		(vr_isAdmin = 1 OR pg.status = N'Accepted' OR pg.status = N'CitationNeeded' OR (
			pg.status = N'Pending' AND vr_viewer_user_id IS NOT NULL AND 
			pg.creator_user_id = vr_viewer_user_id
		)) AND pg.deleted = vr_deleted
		
	EXEC wk_p_get_paragraphs_by_ids vr_application_id, vr_paragraph_ids
END;


DROP PROCEDURE IF EXISTS wk_has_paragraph;

CREATE PROCEDURE wk_has_paragraph
	vr_application_id		UUID,
	vr_titleOrOwnerID		UUID,
	vr_viewer_user_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP (1) 1 
		FROM wk_titles 
		WHERE ApplicationID = vr_application_id AND TitleID = vr_titleOrOwnerID
	) BEGIN
		SELECT TOP(1) 1
		FROM wk_paragraphs AS p
		WHERE p.application_id = vr_application_id AND p.title_id = vr_titleOrOwnerID AND
			(vr_viewer_user_id IS NULL OR p.status = N'Accepted' OR 
			p.status = N'CitationNeeded' OR p.creator_user_id = vr_viewer_user_id) AND p.deleted = FALSE
	END
	ELSE BEGIN
		SELECT TOP(1) 1
		FROM wk_titles AS t
			INNER JOIN wk_paragraphs AS p
			ON p.application_id = vr_application_id AND p.title_id = t.title_id
		WHERE t.application_id = vr_application_id AND t.owner_id = vr_titleOrOwnerID AND
			(vr_viewer_user_id IS NULL OR p.status = N'Accepted' OR 
			p.status = N'CitationNeeded' OR p.creator_user_id = vr_viewer_user_id) AND p.deleted = FALSE
	END
	
	SELECT -1
END;


DROP PROCEDURE IF EXISTS wk_p_get_changes_by_ids;

CREATE PROCEDURE wk_p_get_changes_by_ids
	vr_application_id	UUID,
	vr_change_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_change_ids GuidTableType
	INSERT INTO vr_change_ids SELECT * FROM vr_change_idsTemp
	
	SELECT c.change_id AS change_id,
		   c.paragraph_id AS paragraph_id,
		   c.title AS title,
		   c.body_text AS body_text,
		   c.status AS status,
		   c.applied AS applied,
		   c.send_date AS send_date,
		   c.user_id AS sender_user_id,
		   un.username AS sender_username,
		   un.first_name AS sender_first_name,
		   un.last_name AS sender_last_name
	FROM vr_change_ids AS external_ids
		INNER JOIN wk_changes AS c
		ON c.application_id = vr_application_id AND c.change_id = external_ids.value
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = c.user_id
END;


DROP PROCEDURE IF EXISTS wk_get_changes_by_ids;

CREATE PROCEDURE wk_get_changes_by_ids
	vr_application_id	UUID,
	vr_strChangeIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_change_ids GuidTableType
	INSERT INTO vr_change_ids
	SELECT DISTINCT ref.value FROM GFN_StrToGuidTable(vr_strChangeIDs, vr_delimiter) AS ref
	
	EXEC wk_p_get_changes_by_ids vr_application_id, vr_change_ids
END;


DROP PROCEDURE IF EXISTS wk_get_paragraph_changes;

CREATE PROCEDURE wk_get_paragraph_changes
	vr_application_id		UUID,
	vr_strParagraphIDs	varchar(max),
	vr_delimiter			char,
	vr_creator_user_id		UUID,
	vr_status				varchar(20),
	vr_applied		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_paragraph_ids GuidTableType
	INSERT INTO vr_paragraph_ids
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strParagraphIDs, vr_delimiter) AS ref
	
	DECLARE vr_change_ids GuidTableType
	
	INSERT INTO vr_change_ids
	SELECT DISTINCT ch.change_id
	FROM vr_paragraph_ids AS external_ids
		INNER JOIN wk_changes AS ch
		ON ch.paragraph_id = external_ids.value
	WHERE ch.application_id = vr_application_id AND 
		(vr_creator_user_id IS NULL OR ch.user_id = vr_creator_user_id) AND
		(vr_status IS NULL OR ch.status = vr_status) AND
		(vr_applied IS NULL OR ch.applied = vr_applied) AND ch.deleted = FALSE
	
	EXEC wk_p_get_changes_by_ids vr_application_id, vr_change_ids
END;


DROP PROCEDURE IF EXISTS wk_get_last_pending_change;

CREATE PROCEDURE wk_get_last_pending_change
	vr_application_id	UUID,
	vr_paragraph_id	UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_change_ids GuidTableType
	
	INSERT INTO vr_change_ids
	SELECT ChangeID 
	FROM wk_changes
	WHERE ApplicationID = vr_application_id AND ParagraphID = vr_paragraph_id AND 
		UserID = vr_user_id AND deleted = FALSE AND status = N'Pending'
	
	EXEC wk_p_get_changes_by_ids vr_application_id, vr_change_ids
END;


DROP PROCEDURE IF EXISTS wk_get_paragraph_related_user_ids;

CREATE PROCEDURE wk_get_paragraph_related_user_ids
	vr_application_id	UUID,
	vr_paragraph_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids Table(id UUID)
	
	DECLARE vr_creatorID UUID, vr_modifier_id UUID
	
	SELECT vr_creatorID = ph.creator_user_id, vr_modifier_id = ph.last_modifier_user_id
	FROM wk_paragraphs AS ph
	WHERE ph.application_id = vr_application_id AND ph.paragraph_id = vr_paragraph_id
	
	INSERT INTO vr_user_ids (id) VALUES(vr_creatorID)
	IF vr_modifier_id IS NOT NULL INSERT INTO vr_user_ids (id) VALUES(vr_modifier_id)
	
	INSERT INTO vr_user_ids
	SELECT DISTINCT ch.user_id AS id
	FROM wk_changes AS ch
	WHERE ch.application_id = vr_application_id AND ch.paragraph_id = vr_paragraph_id AND 
		(ch.applied = 1 OR ch.status = N'Accepted')
		
	SELECT DISTINCT i_ds.id AS id
	FROM vr_user_ids AS i_ds
		INNER JOIN users_normal AS usr
		ON i_ds.id = usr.user_id
	WHERE usr.application_id = vr_application_id AND usr.is_approved = TRUE
END;


DROP PROCEDURE IF EXISTS wk_get_changed_wiki_owner_ids;

CREATE PROCEDURE wk_get_changed_wiki_owner_ids
	vr_application_id	UUID,
	vr_strOwnerIDs	varchar(max),
	vr_delimter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strOwnerIDs, vr_delimter) AS ref
	
	SELECT external_ids.value AS id
	FROM vr_owner_ids AS external_ids
	WHERE EXISTS(
			SELECT TOP(1) * 
			FROM wk_titles AS tt
				INNER JOIN wk_paragraphs AS pg
				ON pg.application_id = vr_application_id AND pg.title_id = tt.title_id
				INNER JOIN wk_changes AS ch
				ON ch.application_id = vr_application_id AND ch.paragraph_id = pg.paragraph_id
			WHERE tt.application_id = vr_application_id AND 
				tt.owner_id = external_ids.value AND tt.deleted = FALSE AND 
				pg.deleted = FALSE AND ch.status = N'Pending' AND ch.deleted = FALSE
		)
END;


DROP PROCEDURE IF EXISTS wk_p_create_wiki;

DROP PROCEDURE IF EXISTS wk_get_wiki_owner;

CREATE PROCEDURE wk_get_wiki_owner
	vr_application_id	UUID,
	vr_iD				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_id UUID
	DECLARE vr_owner_type varchar(20)
	
	SELECT vr_owner_id = OwnerID, vr_owner_type = OwnerType
	FROM wk_titles
	WHERE ApplicationID = vr_application_id AND TitleID = vr_iD
	
	IF vr_owner_id IS NULL BEGIN	
		SELECT vr_owner_id = tt.owner_id, vr_owner_type = tt.owner_type
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS p
			ON p.application_id = vr_application_id AND p.title_id = tt.title_id
		WHERE tt.application_id = vr_application_id AND p.paragraph_id = vr_iD
	END
	
	IF vr_owner_id IS NULL BEGIN
		SELECT vr_owner_id = tt.owner_id, vr_owner_type = tt.owner_type
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS p
			ON p.application_id = vr_application_id AND p.title_id = tt.title_id
			INNER JOIN wk_changes AS ch
			ON ch.application_id = vr_application_id AND ch.paragraph_id = p.paragraph_id
		WHERE tt.application_id = vr_application_id AND ch.change_id = vr_iD
	END
	
	SELECT vr_owner_id AS owner_id, vr_owner_type AS owner_type
END;


DROP PROCEDURE IF EXISTS wk_get_wiki_content;

CREATE PROCEDURE wk_get_wiki_content
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT wk_fn_get_wiki_content(vr_application_id, vr_owner_id)
END;


DROP PROCEDURE IF EXISTS wk_get_titles_count;

CREATE PROCEDURE wk_get_titles_count
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_isAdmin	 BOOLEAN,
	vr_current_user_id	UUID,
	vr_removed	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(TitleID)
	FROM wk_titles AS t
	WHERE t.application_id = vr_application_id AND 
		t.owner_id = vr_owner_id AND (vr_isAdmin = 1 OR t.status = N'Accepted' OR (
			t.status = N'CitationNeeded' AND vr_current_user_id IS NOT NULL AND 
			t.creator_user_id = vr_current_user_id
		)) AND (vr_removed IS NULL OR t.deleted = vr_removed)
END;


DROP PROCEDURE IF EXISTS wk_get_paragraphs_count;

CREATE PROCEDURE wk_get_paragraphs_count
	vr_application_id	UUID,
	vr_strTitleIDs	varchar(max),
	vr_delimiter		char,
	vr_isAdmin	 BOOLEAN,
	vr_current_user_id	UUID,
	vr_removed	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_titleIDs GuidTableType
	
	INSERT INTO vr_titleIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strTitleIDs, vr_delimiter) AS ref
	
	SELECT t.value AS id, COUNT(p.paragraph_id) count
	FROM vr_titleIDs AS t
		LEFT JOIN wk_paragraphs AS p
		ON p.application_id = vr_application_id AND p.title_id = t.value
	WHERE (vr_isAdmin = 1 OR p.status = N'Accepted' OR p.status = N'CitationNeeded' OR (
			p.status = N'Pending' AND vr_current_user_id IS NOT NULL AND 
			p.creator_user_id = vr_current_user_id
		)) AND (vr_removed IS NULL OR p.deleted = vr_removed)
	GROUP BY t.value
END;


DROP PROCEDURE IF EXISTS wk_get_changes_count;

CREATE PROCEDURE wk_get_changes_count
	vr_application_id		UUID,
	vr_strParagraphIDs	varchar(max),
	vr_delimiter			char,
	vr_applied		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_paragraph_ids GuidTableType
	
	INSERT INTO vr_paragraph_ids(Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strParagraphIDs, vr_delimiter) AS ref
	
	SELECT p.value AS id, COUNT(c.change_id) count
	FROM vr_paragraph_ids AS p
		LEFT JOIN wk_changes AS c
		ON c.application_id = vr_application_id AND c.paragraph_id = p.value
	WHERE (c.status = N'Accepted' OR c.status = N'CitationNeeded') AND 
		(vr_applied IS NULL OR c.applied = vr_applied) AND c.deleted = FALSE
	GROUP BY p.value
END;


DROP PROCEDURE IF EXISTS wk_last_modification_date;

CREATE PROCEDURE wk_last_modification_date
	vr_application_id		UUID,
	vr_owner_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	-- Last Modification Date for both existing and deleted paragraphs & titles
	-- because delete is a sort of modification
	
	SELECT MAX(p.creation_date)
	FROM wk_titles AS t
		INNER JOIN wk_paragraphs AS p
		ON p.application_id = vr_application_id AND p.title_id = t.title_id AND
			(p.status = N'Accepted' OR p.status = N'CitationNeeded')
	WHERE t.application_id = vr_application_id AND t.owner_id = vr_owner_id
END;


DROP PROCEDURE IF EXISTS wk_wiki_authors;

CREATE PROCEDURE wk_wiki_authors
	vr_application_id		UUID,
	vr_owner_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT *
	FROM (
			SELECT c.user_id AS id, COUNT(c.change_id) AS count
			FROM wk_titles AS t
				INNER JOIN wk_paragraphs AS p
				ON p.application_id = vr_application_id AND p.title_id = t.title_id AND
					(p.status = N'Accepted' OR p.status = N'CitationNeeded')
				INNER JOIN wk_changes AS c
				ON c.application_id = vr_application_id AND 
					c.paragraph_id = p.paragraph_id AND c.applied = 1 AND c.deleted = FALSE
			WHERE t.application_id = vr_application_id AND t.owner_id = vr_owner_id AND t.deleted = FALSE
			GROUP BY c.user_id
		) AS ref
	ORDER BY ref.count DESC
END;

DROP PROCEDURE IF EXISTS de_update_nodes;

CREATE PROCEDURE de_update_nodes
	vr_application_id			UUID,
	vr_nodeTypeID				UUID,
	vr_nodeTypeAdditionalID	varchar(50),
    vr_nodesTemp				ExchangeNodeTableType readonly,
    vr_creator_user_id			UUID,
    vr_creation_date		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_nodes ExchangeNodeTableType
	INSERT INTO vr_nodes SELECT * FROM vr_nodesTemp
	
	IF vr_nodeTypeID IS NULL 
		SET vr_nodeTypeID = cn_fn_get_node_type_id(vr_application_id, vr_nodeTypeAdditionalID)
	
	DECLARE vr_not_existing ExchangeNodeTableType
	
	INSERT INTO vr_not_existing
	SELECT * 
	FROM vr_nodes AS external_nodes
	WHERE NOT((external_nodes.node_id IS NULL OR COALESCE(external_nodes.node_additional_id, N'') = N'') AND
		(external_nodes.name IS NULL OR external_nodes.name = N'')) AND
		NOT EXISTS(
			SELECT TOP(1) * 
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND nd.node_type_id = vr_nodeTypeID AND 
				external_nodes.node_additional_id IS NOT NULL AND nd.additional_id = external_nodes.node_additional_id
		)
		
	DECLARE vr__count INTEGER
	SET vr__count = (SELECT COUNT(*) FROM vr_not_existing)
	
	IF vr__count > 0 BEGIN
		INSERT INTO cn_nodes(
			ApplicationID,
			NodeID,
			NodeTypeID,
			AdditionalID,
			Name,
			description,
			Tags,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT vr_application_id, COALESCE(ne.node_id, gen_random_uuid()), vr_nodeTypeID, ne.node_additional_id, 
			gfn_verify_string(ne.name), gfn_verify_string(ne.abstract), 
			gfn_verify_string(ne.tags), vr_creator_user_id, vr_creation_date, 0
		FROM vr_not_existing AS ne
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM vr_nodes 
		WHERE COALESCE(NodeAdditionalID, N'') <> N'' AND COALESCE(Name, N'') <> N''
	) BEGIN
		UPDATE ND
			SET Name = gfn_verify_string(external_nodes.name),
				Tags = COALESCE(gfn_verify_string(external_nodes.tags), nd.tags),
				description = COALESCE(gfn_verify_string(external_nodes.abstract), nd.description)
		FROM vr_nodes AS external_nodes
			INNER JOIN cn_nodes AS nd
			ON nd.additional_id = external_nodes.node_additional_id
		WHERE nd.application_id = vr_application_id AND 
			COALESCE(external_nodes.node_additional_id, N'') <> N'' AND
			nd.node_type_id = vr_nodeTypeID AND COALESCE(external_nodes.name, N'') <> N''
			
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	-- Update Sequence Number
	UPDATE ND
		SET SequenceNumber = x.row_num
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT 1) ASC) AS row_num,
					n.*
			FROM vr_nodes AS n
		) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_type_id = vr_nodeTypeID AND
			COALESCE(nd.additional_id, N'') <> N'' AND nd.additional_id = x.node_additional_id
	-- end of Update Sequence Number
	
	DECLARE vr_have_parent ExchangeNodeTableType
	INSERT INTO vr_have_parent(NodeAdditionalID, ParentAdditionalID)
	SELECT nd.node_additional_id, nd.parent_additional_id
	FROM vr_nodes AS nd
	WHERE COALESCE(nd.node_additional_id, N'') <> N'' AND COALESCE(nd.parent_additional_id, N'') <> ''
	
	IF EXISTS(SELECT TOP(1) * FROM vr_have_parent) BEGIN
		UPDATE ND
			SET ParentNodeID = ot.node_id,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		FROM vr_have_parent AS external_nodes
			INNER JOIN cn_nodes AS nd
			ON nd.additional_id = external_nodes.node_additional_id
			INNER JOIN cn_nodes AS ot
			ON ot.additional_id = external_nodes.parent_additional_id
		WHERE nd.application_id = vr_application_id AND ot.application_id = vr_application_id AND
			nd.node_type_id = vr_nodeTypeID AND ot.node_type_id = vr_nodeTypeID
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE vr_have_not_parent ExchangeNodeTableType
	INSERT INTO vr_have_not_parent(NodeAdditionalID, ParentAdditionalID)
	SELECT nd.node_additional_id, nd.parent_additional_id
	FROM vr_nodes AS nd
	WHERE COALESCE(nd.node_additional_id, N'') <> N'' AND COALESCE(nd.parent_additional_id, N'') = ''
	
	IF EXISTS(SELECT TOP(1) * FROM vr_have_not_parent) BEGIN
		UPDATE ND
			SET ParentNodeID = NULL,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		FROM vr_have_not_parent AS external_nodes
			INNER JOIN cn_nodes AS nd
			ON nd.additional_id = external_nodes.node_additional_id
		WHERE nd.application_id = vr_application_id AND nd.node_type_id = vr_nodeTypeID
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
	
	SELECT n.node_id AS id
	FROM vr_not_existing AS n
	WHERE n.node_id IS NOT NULL
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS de_update_node_ids;

CREATE PROCEDURE de_update_node_ids
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_strNodeIDs	 VARCHAR(max),
	vr_inner_delimiter	char,
	vr_outer_delimiter	char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_values TABLE (NodeID UUID, NewAdditionalID VARCHAR(200))
	
	INSERT INTO vr_values (NodeID, NewAdditionalID)
	SELECT DISTINCT nd.node_id, ref.second_value
	FROM gfn_str_to_string_pair_table(vr_strNodeIDs, vr_inner_delimiter, vr_outer_delimiter) AS ref
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_type_id = vr_nodeTypeID AND nd.additional_id = ref.first_value
	
	UPDATE ND
		SET AdditionalID = x.new_additional_id,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM (
			SELECT v.*
			FROM vr_values AS v
				LEFT JOIN cn_nodes AS n
				ON n.application_id = vr_application_id AND n.node_type_id = vr_nodeTypeID AND
					n.additional_id = v.new_additional_id AND n.node_id <> v.node_id
			WHERE COALESCE(v.new_additional_id, N'') <> N'' AND n.node_id IS NULL
		) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS de_remove_nodes;

CREATE PROCEDURE de_remove_nodes
	vr_application_id	UUID,
	vr_strNodeIDs	 VARCHAR(max),
	vr_inner_delimiter	char,
	vr_outer_delimiter	char,
    vr_current_user_id	UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids(Value)
	SELECT DISTINCT nd.node_id
	FROM gfn_str_to_string_pair_table(vr_strNodeIDs, vr_inner_delimiter, vr_outer_delimiter) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			nd.type_additional_id = ref.first_value AND nd.node_additional_id = ref.second_value
	
	UPDATE ND
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_node_ids AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.value
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS de_update_users;

CREATE PROCEDURE de_update_users
	vr_application_id	UUID,
    vr_usersTemp		ExchangeUserTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_users ExchangeUserTableType
	INSERT INTO vr_users SELECT * FROM vr_usersTemp
	
	DECLARE vr__result INTEGER = 0
	
	DECLARE vr_temp_users TABLE(ID INTEGER IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
		UserID UUID, NewUserName VARCHAR(255),
		FirstName VARCHAR(255), LastName VARCHAR(255), EmploymentType varchar(50))
	
	INSERT INTO vr_temp_users(
		UserID, NewUserName, FirstName, LastName, EmploymentType)
	SELECT usr.user_id, ref.new_username, gfn_verify_string(ref.first_name),
		gfn_verify_string(ref.last_name), ref.employment_type
	FROM vr_users AS ref
		INNER JOIN rv_users AS usr
		ON usr.lowered_username = LOWER(ref.username)
		INNER JOIN usr_user_applications AS app
		ON app.application_id = vr_application_id AND app.user_id = usr.user_id
	
	-- Create New Users
	DECLARE vr_new_users ExchangeUserTableType
	DECLARE vr_first_passwords GuidStringTableType
	
	INSERT INTO vr_new_users (UserID, UserName, FirstName, LastName, 
		password, PasswordSalt, EncryptedPassword)
	SELECT gen_random_uuid(), ref.username, ref.first_name, ref.last_name, 
		ref.password, ref.password_salt, ref.encrypted_password
	FROM vr_users AS ref
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(ref.username) AND
			COALESCE(ref.new_username, N'') = N''
	WHERE COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N'' AND
		COALESCE(ref.encrypted_password, N'') <> N'' AND un.user_id IS NULL
	
	INSERT INTO vr_first_passwords (FirstValue, SecondValue)
	SELECT u.user_id, u.encrypted_password
	FROM vr_new_users AS u
	
	DECLARE vr__error_message VARCHAR(255)
	
	EXEC usr_p_create_users vr_application_id, vr_new_users, vr_now, 
		vr__result output, vr__error_message output
	
	EXEC usr_p_save_password_history_bulk vr_first_passwords, 1, vr_now, vr__result output
	-- end of Create New Users
	
	-- Reset passwords
	DECLARE vr_change_pass_users ExchangeUserTableType
	
	INSERT INTO vr_change_pass_users (UserID, password, PasswordSalt, EncryptedPassword)
	SELECT un.user_id, ref.password, ref.password_salt, ref.encrypted_password
	FROM vr_users AS ref
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(ref.username)
		LEFT JOIN vr_first_passwords AS f
		ON f.first_value = un.user_id
	WHERE ref.reset_password = 1 AND f.first_value IS NULL AND 
		COALESCE(ref.password, N'') <> N'' AND COALESCE(ref.password_salt, N'') <> N''
	
	UPDATE M
		SET password = c.password,
			PasswordSalt = c.password_salt
	FROM vr_change_pass_users AS c
		INNER JOIN rv_membership AS m
		ON m.user_id = c.user_id
	
	DECLARE vr_changed_passwords GuidStringTableType
	
	INSERT INTO vr_changed_passwords(FirstValue, SecondValue)
	SELECT u.user_id, u.encrypted_password
	FROM vr_change_pass_users AS u
	
	EXEC usr_p_save_password_history_bulk vr_changed_passwords , 1, vr_now, vr__result output
	-- end of Reset passwords
	
	
	UPDATE P
		SET FirstName = ref.first_name
	FROM vr_temp_users AS ref
		INNER JOIN usr_profile AS p
		ON p.user_id = ref.user_id
	WHERE COALESCE(ref.first_name, N'') <> N''
	
	UPDATE P
		SET LastName = ref.last_name
	FROM vr_temp_users AS ref
		INNER JOIN usr_profile AS p
		ON p.user_id = ref.user_id
	WHERE COALESCE(ref.last_name, N'') <> N''
	
	UPDATE P
		SET EmploymentType = ref.employment_type
	FROM vr_temp_users AS ref
		INNER JOIN usr_user_applications AS p
		ON p.application_id = vr_application_id AND p.user_id = ref.user_id
	WHERE COALESCE(ref.employment_type, N'') <> N''
	
	UPDATE USR
		SET UserName = x.new_username,
			LoweredUserName = LOWER(x.new_username)
	FROM (
			SELECT u.*
			FROM vr_temp_users AS u
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND 
					un.lowered_username = LOWER(u.new_username) AND u.user_id <> un.user_id
			WHERE COALESCE(u.new_username, N'') <> N'' AND un.user_id IS NULL
		) AS x
		INNER JOIN rv_users AS usr
		ON usr.user_id = x.user_id
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS de_update_members;

CREATE PROCEDURE de_update_members
	vr_application_id	UUID,
    vr_members_temp	ExchangeMemberTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_members ExchangeMemberTableType
	INSERT INTO vr_members SELECT * FROM vr_members_temp
	
	DECLARE vr_mbrs Table(
		NodeID UUID,
		UserID UUID,
		IsAdmin BOOLEAN,
		UniqueAdmin BOOLEAN
	)
	
	INSERT INTO vr_mbrs (NodeID, UserID, IsAdmin, UniqueAdmin)
	SELECT	nd.node_id,
			un.user_id,
			CAST(MAX(CAST(COALESCE(m.is_admin, FALSE) AS integer)) AS boolean),
			CAST(MAX(CAST(COALESCE(s.unique_admin_member, FALSE) AS integer)) AS boolean)
	FROM vr_members AS m
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			(m.node_id IS NULL AND nd.type_additional_id = m.node_type_additional_id AND
			nd.node_additional_id = m.node_additional_id) OR
			(m.node_id IS NOT NULL AND nd.node_id = m.node_id)
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(m.username)
	GROUP BY nd.node_id, un.user_id
	
	DECLARE vr__result INTEGER
	
	-- Add members
	DECLARE vr_m_ids GuidPairTableType
	
	INSERT INTO vr_m_ids (FirstValue, SecondValue)
	SELECT NodeID, UserID FROM vr_mbrs
	
	EXEC cn_p_add_accepted_members vr_application_id, vr_m_ids, vr_now, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	--end of Add members
	
	--Update admins
	UPDATE NM
		SET IsAdmin = (
			CASE
				WHEN n_ids.unique_admin = 0 THEN COALESCE(ref.is_admin, nm.is_admin) 
				WHEN ref.node_id IS NULL
					THEN (CASE WHEN n_ids.admins_count = 0 THEN nm.is_admin ELSE 0 END)
				ELSE (CASE WHEN n_ids.admins_count <= 1 THEN ref.is_admin ELSE 0 END)
			END
		)
	FROM (
			SELECT	x.node_id, 
					CAST(MAX(CAST(x.unique_admin AS integer)) AS boolean) AS unique_admin, 
					SUM(CAST(x.is_admin AS integer)) AS admins_count
			FROM vr_mbrs AS x
			GROUP BY x.node_id
		) AS n_ids
		INNER JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n_ids.node_id AND nm.deleted = FALSE
		LEFT JOIN vr_mbrs AS ref
		ON ref.node_id = nm.node_id AND ref.user_id = nm.user_id
	--end of Update admins
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS de_update_experts;

CREATE PROCEDURE de_update_experts
	vr_application_id	UUID,
    vr_expertsTemp	ExchangeMemberTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_experts ExchangeMemberTableType
	INSERT INTO vr_experts SELECT * FROM vr_expertsTemp
	
	DECLARE vr_xPRTS Table(
		NodeID UUID,
		UserID UUID,
		exists BOOLEAN,
		AdditionalID varchar(50)
	)
	
	INSERT INTO vr_xPRTS (NodeID, UserID, AdditionalID)
	SELECT	nd.node_id,
			un.user_id,
			x.node_additional_id
	FROM vr_experts AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			(x.node_id IS NULL AND nd.type_additional_id = x.node_type_additional_id AND
			nd.node_additional_id = x.node_additional_id) OR
			(x.node_id IS NOT NULL AND nd.node_id = x.node_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(x.username)
		
	UPDATE X
		SET exists = TRUE
	FROM vr_xPRTS AS x
		INNER JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND 
			ex.node_id = x.node_id AND ex.user_id = x.user_id
		
	DECLARE vr_count INTEGER, vr_existingCount INTEGER
	
	SELECT	vr_count = COUNT(x.node_id),
			vr_existingCount = SUM(CAST((CASE WHEN x.exists = TRUE THEN 1 ELSE 0 END) AS integer))
	FROM vr_xPRTS AS x
	
	IF vr_existingCount > 0 BEGIN
		UPDATE EX
			SET approved = TRUE
		FROM vr_xPRTS AS x
			INNER JOIN cn_experts AS ex
			ON ex.node_id = x.node_id AND ex.user_id = x.user_id
		WHERE ex.application_id = vr_application_id AND x.exists = TRUE
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF (vr_count - vr_existingCount) > 0 BEGIN
		INSERT INTO cn_experts(
			ApplicationID,
			NodeID,
			UserID,
			Approved,
			ReferralsCount,
			ConfirmsPercentage,
			SocialApproved,
			UniqueID
		)
		SELECT	vr_application_id,
				x.node_id,
				x.user_id,
				1,
				0,
				0,
				0,
				gen_random_uuid()
		FROM vr_xPRTS AS x
		WHERE COALESCE(x.exists, FALSE) = 0
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS de_update_relations;

CREATE PROCEDURE de_update_relations
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_relationsTemp	ExchangeRelationTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_relations ExchangeRelationTableType
	INSERT INTO vr_relations SELECT * FROM vr_relationsTemp
	
	DECLARE vr_relation_type_id UUID = 
		cn_fn_get_related_relation_type_id(vr_application_id)
	
	UPDATE NR
		SET LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now,
		 deleted = FALSE
	FROM (
			SELECT DISTINCT *
			FROM (
				SELECT	SourceTypeAdditionalID,
						SourceAdditionalID,
						DestinationTypeAdditionalID,
						DestinationAdditionalID
				FROM vr_relations AS r
				
				UNION ALL
				
				SELECT	DestinationTypeAdditionalID,
						DestinationAdditionalID,
						SourceTypeAdditionalID,
						SourceAdditionalID
				FROM vr_relations AS r
				WHERE r.bidirectional = 1
			) AS x
		) AS r
		INNER JOIN cn_node_types AS snt
		ON snt.application_id = vr_application_id AND snt.additional_id = r.source_type_additional_id
		INNER JOIN cn_nodes AS snd
		ON snd.application_id = vr_application_id AND snd.node_type_id = snt.node_type_id AND
			snd.additional_id = r.source_additional_id
		INNER JOIN cn_node_types AS dnt
		ON dnt.application_id = vr_application_id AND 
			dnt.additional_id = r.destination_type_additional_id
		INNER JOIN cn_nodes AS dnd
		ON dnd.application_id = vr_application_id AND dnd.node_type_id = dnt.node_type_id AND
			dnd.additional_id = r.destination_additional_id
		INNER JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.source_node_id = snd.node_id AND
			nr.destination_node_id = dnd.node_id AND nr.property_id = vr_relation_type_id
	
	DECLARE vr_cnt INTEGER = @vr_rowcount
	
	INSERT INTO cn_node_relations (
		ApplicationID,
		SourceNodeID,
		DestinationNodeID,
		PropertyID,
		CreatorUserID,
		CreationDate,
		Deleted,
		UniqueID
	)
	SELECT	vr_application_id, 
			snd.node_id, 
			dnd.node_id, 
			vr_relation_type_id, 
			vr_current_user_id, 
			vr_now, 
			0, 
			gen_random_uuid()
	FROM (
			SELECT DISTINCT *
			FROM (
				SELECT	SourceTypeAdditionalID,
						SourceAdditionalID,
						DestinationTypeAdditionalID,
						DestinationAdditionalID
				FROM vr_relations AS r
				
				UNION ALL
				
				SELECT	DestinationTypeAdditionalID,
						DestinationAdditionalID,
						SourceTypeAdditionalID,
						SourceAdditionalID
				FROM vr_relations AS r
				WHERE r.bidirectional = 1
			) AS x
		) AS r
		INNER JOIN cn_node_types AS snt
		ON snt.application_id = vr_application_id AND snt.additional_id = r.source_type_additional_id
		INNER JOIN cn_nodes AS snd
		ON snd.application_id = vr_application_id AND snd.node_type_id = snt.node_type_id AND
			snd.additional_id = r.source_additional_id
		INNER JOIN cn_node_types AS dnt
		ON dnt.application_id = vr_application_id AND 
			dnt.additional_id = r.destination_type_additional_id
		INNER JOIN cn_nodes AS dnd
		ON dnd.application_id = vr_application_id AND dnd.node_type_id = dnt.node_type_id AND
			dnd.additional_id = r.destination_additional_id
		LEFT JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.source_node_id = snd.node_id AND
			nr.destination_node_id = dnd.node_id AND nr.property_id = vr_relation_type_id
	WHERE nr.source_node_id IS NULL
	
	SELECT @vr_rowcount + vr_cnt
END;


DROP PROCEDURE IF EXISTS de_update_authors;

CREATE PROCEDURE de_update_authors
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_authorsTemp	ExchangeAuthorTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_authors ExchangeAuthorTableType
	INSERT INTO vr_authors SELECT * FROM vr_authorsTemp
	
	DECLARE vr_shares TABLE (NodeID UUID, UserID UUID, Percentage INTEGER)
	
	INSERT INTO vr_shares (NodeID, UserID, Percentage)
	SELECT nd.node_id, un.user_id, MAX(a.percentage)
	FROM vr_authors AS a
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.type_additional_id = a.node_type_additional_id AND
			nd.node_additional_id = a.node_additional_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.username IS NOT NULL AND LOWER(un.username) = LOWER(a.username)
	WHERE COALESCE(a.node_type_additional_id, N'') <> N'' AND COALESCE(a.node_additional_id, N'') <> N'' AND 
		a.percentage IS NOT NULL AND a.percentage > 0 AND a.percentage <= 100
	GROUP BY nd.node_id, un.user_id
	
	DELETE X
	FROM vr_shares AS x
		INNER JOIN (
			SELECT s.node_id, SUM(s.percentage) AS summation
			FROM vr_shares AS s
			GROUP BY s.node_id
		) AS ref
		ON ref.node_id = x.node_id
	WHERE ref.summation <> 100
	
	UPDATE NC
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM (SELECT DISTINCT NodeID FROM vr_shares) AS s
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = s.node_id
		
	UPDATE NC
		SET deleted = FALSE,
			CollaborationShare = CAST(s.percentage AS float),
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_shares AS s
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = s.node_id AND nc.user_id = s.user_id
	
	DECLARE vr_cnt INTEGER = @vr_rowcount
	
	INSERT INTO cn_node_creators (ApplicationID, NodeID, UserID, CollaborationShare,
		CreatorUserID, CreationDate, Deleted, UniqueID)
	SELECT	vr_application_id, s.node_id, s.user_id, CAST(s.percentage AS float), 
			vr_current_user_id, vr_now, 0, gen_random_uuid()
	FROM vr_shares AS s
		LEFT JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = s.node_id AND nc.user_id = s.user_id
	WHERE nc.node_id IS NULL
	
	SELECT @vr_rowcount + vr_cnt
END;


DROP PROCEDURE IF EXISTS de_update_user_confidentialities;

CREATE PROCEDURE de_update_user_confidentialities
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_strInput		varchar(max),
    vr_inner_delimiter	char,
    vr_outer_delimiter char,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_values TABLE (UserID UUID, ConfidentialityID UUID)
	
	INSERT INTO vr_values (UserID, ConfidentialityID)
	SELECT DISTINCT un.user_id, l.id
	FROM gfn_str_to_float_string_table(vr_strInput, vr_inner_delimiter, vr_outer_delimiter) AS ref
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(ref.second_value)
		INNER JOIN prvc_confidentiality_levels AS l
		ON l.application_id = vr_application_id AND l.level_id = CAST(ref.first_value AS integer)
		
	UPDATE S
		SET ConfidentialityID = v.confidentiality_id,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_values AS v
		INNER JOIN prvc_settings AS s
		ON s.application_id = vr_application_id AND s.object_id = v.user_id
	
	DECLARE vr_cnt INTEGER = @vr_rowcount
	
	INSERT INTO prvc_settings(
		ApplicationID,
		ObjectID,
		ConfidentialityID,
		CreatorUserID,
		CreationDate
	)
	SELECT vr_application_id, v.user_id, v.confidentiality_id, vr_current_user_id, vr_now
	FROM vr_values AS v
		LEFT JOIN prvc_settings AS s
		ON s.application_id = vr_application_id AND s.object_id = v.user_id
	WHERE s.object_id IS NULL
	
	SELECT @vr_rowcount + vr_cnt
END;


DROP PROCEDURE IF EXISTS de_update_permissions;

CREATE PROCEDURE de_update_permissions
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_itemsTemp		ExchangePermissionTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_items ExchangePermissionTableType
	INSERT INTO vr_items SELECT * FROM vr_itemsTemp
	
	DECLARE vr_values TABLE (
		ObjectID UUID, 
		RoleID UUID, 
		PermissionType VARCHAR(50), 
		Allow BOOLEAN,
		DropAll BOOLEAN
	)
	
	
	INSERT INTO vr_values (ObjectID, RoleID, PermissionType, Allow, DropAll)
	SELECT DISTINCT nd.node_id, COALESCE(un.user_id, grp.node_id), i.permission_type, i.allow, i.drop_all
	FROM vr_items AS i
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.type_additional_id = i.node_type_additional_id AND
			nd.node_additional_id = i.node_additional_id
		LEFT JOIN cn_view_nodes_normal AS grp
		ON grp.application_id = vr_application_id AND grp.type_additional_id = i.group_type_additional_id AND
			grp.node_additional_id = i.group_additional_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(i.username)
	WHERE ((grp.node_id IS NOT NULL OR un.user_id IS NOT NULL) AND i.permission_type IS NOT NULL) OR i.drop_all = 1
	
	
	-- Part 1: Drop All
	UPDATE A
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM prvc_audience AS a
		INNER JOIN (
			SELECT DISTINCT v.object_id
			FROM vr_values AS v
			WHERE v.drop_all = 1
		) AS ref
		ON ref.object_id = a.object_id
	WHERE a.application_id = vr_application_id
	-- end of Part 1: Drop All
	
	DECLARE vr_cnt INTEGER = @vr_rowcount
	
	-- Part 2: Update Existing Items
	UPDATE A
		SET Allow = COALESCE(v.allow, FALSE),
			ExpirationDate = NULL,
		 deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_values AS v
		INNER JOIN prvc_audience AS a
		ON a.application_id = vr_application_id AND a.object_id = v.object_id AND 
			a.role_id = v.role_id AND a.permission_type = v.permission_type
	-- end of Part 2: Update Existing Items
	
	SET vr_cnt = @vr_rowcount + vr_cnt
	
	-- Part 3: Add New Items
	INSERT INTO prvc_audience(
		ApplicationID,
		ObjectID,
		RoleID,
		PermissionType,
		Allow,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, v.object_id, v.role_id, v.permission_type, COALESCE(v.allow, FALSE), vr_current_user_id, vr_now, 0	
	FROM vr_values AS v
		LEFT JOIN prvc_audience AS a
		ON a.application_id = vr_application_id AND a.object_id = v.object_id AND 
			a.role_id = v.role_id AND a.permission_type = v.permission_type
	WHERE v.object_id IS NOT NULL AND v.role_id IS NOT NULL AND 
		v.permission_type IS NOT NULL AND a.object_id IS NULL
	-- end of Part 3: Add New Items
	
	SELECT @vr_rowcount + vr_cnt
END;

DROP PROCEDURE IF EXISTS prvc_initialize_confidentiality_levels;

CREATE PROCEDURE prvc_initialize_confidentiality_levels
	vr_application_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_id UUID = (
		SELECT TOP(1) UserID 
		FROM users_normal
		WHERE ApplicationId = vr_application_id AND LoweredUserName = N'admin'
	)
	
	IF vr_user_id IS NULL BEGIN
		SELECT TOP(1) vr_user_id = a.creator_user_id
		FROM rv_applications AS a
		WHERE a.application_id = vr_application_id
	END
	
	IF vr_user_id IS NULL RETURN 1
	
	DECLARE vr_now TIMESTAMP = GETDATE()
	
	DECLARE vr_tbl Table(LevelID INTEGER, Title VARCHAR(100))
	
	INSERT INTO vr_tbl (LevelID, Title)
	VALUES	(1,	N'فاقد طبقه بندی'),
			(2,	N'محرمانه'),
			(3,	N'خیلی محرمانه'),
			(4,	N'سری'),
			(5,	N'به کلی سری')
	
	IF NOT EXISTS(
		SELECT TOP(1) *
		FROM prvc_confidentiality_levels AS l
		WHERE l.application_id = vr_application_id
	) BEGIN
		INSERT INTO prvc_confidentiality_levels (ApplicationID, ID, LevelID, Title, 
			CreatorUserID, CreationDate, Deleted)
		SELECT vr_application_id, gen_random_uuid(), t.level_id, t.title, vr_user_id, vr_now, 0
		FROM vr_tbl AS t
	END
    
    RETURN 1
END;


DROP PROCEDURE IF EXISTS prvc_refine_access_roles;

CREATE PROCEDURE prvc_refine_access_roles
	vr_application_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
    DECLARE vr_tbl Table(ID INTEGER identity(1,1) primary key clustered, 
	OldValue varchar(1000), NewValue varchar(1000), Title VARCHAR(1000), UQID UUID)

	INSERT INTO vr_tbl (OldValue, NewValue, Title)
	VALUES	('AssignUsersAsExpert','', N''),
			('AssignUsersToDepartments','', N''),
			('AssignUsersToProcesses','', N''),
			('AssignUsersToProjects','', N''),
			('CopCreation','', N''),
			('DefaultContentRegistration','', N''),
			('DepartmentsManipulation','', N''),
			('KDsManagement','', N''),
			('ManageDepartmentGroups','', N''),
			('OrganizationalProperties','', N''),
			('ProcessesManagement','', N''),
			('ProjectsManagement','', N''),
			('Navigation','', N''),
			('VisualKMap','', N''),
			('AssignUsersToClassifications','ManageConfidentialityLevels', N'مدیریت سطوح محرمانگی'),
			('ContentsManagement','ContentsManagement', N'مديريت مستندات'),
			('DepsAndUsersImport','DataImport', N'ورود اطلاعات از طریق XML'),
			('ManagementSystem','ManagementSystem', N'مديريت سيستم'),
			('ManageOntology','ManageOntology', N'پیکربندی نقشه'),
			('Reports','Reports', N'گزارشات'),
			('UserGroupsManagement','UserGroupsManagement', N'مدیران سامانه'),
			('UsersManagement','UsersManagement', N'کاربران'),
			('ManageWorkflow','ManageWorkflow', N'جریان های کاری'),
			('ManageForms','ManageForms', N'فرم ها'),
			('ManagePolls','ManagePolls', N'نظرسنجی ها'),
			('KnowledgeAdmin','KnowledgeAdmin', N'فرآیندهای ارزیابی دانش'),
			('SMSEMailNotifier','SMSEMailNotifier', N'پیام کوتاه و پست الکترونیکی'),
			('','ManageQA', N'پرسش و پاسخ'),
			('','RemoteServers', N'سرورهای راه دور')
			
	UPDATE AR
		SET ar.name = t.new_value
	FROM vr_tbl AS t
		INNER JOIN usr_access_roles AS ar
		ON ar.application_id = vr_application_id AND LOWER(ar.name) = LOWER(t.old_value)
		
	DELETE UAR
	FROM usr_user_group_permissions AS uar
		INNER JOIN usr_access_roles AS ar
		ON ar.application_id = vr_application_id AND ar.role_id = Uar.role_id
	WHERE uar.application_id = vr_application_id AND 
		ar.name NOT IN (SELECT NewValue FROM vr_tbl AS t WHERE t.new_value <> '')
	
	DELETE AR
	FROM usr_access_roles AS ar
	WHERE ar.application_id = vr_application_id AND 
		ar.name NOT IN (SELECT NewValue FROM vr_tbl AS t WHERE t.new_value <> '')

	DELETE vr_tbl
	WHERE NewValue = ''

	INSERT INTO usr_access_roles (ApplicationID, RoleID, Name, Title)
	SELECT vr_application_id, gen_random_uuid(), t.new_value, N''
	FROM vr_tbl AS t
	WHERE t.new_value <> '' AND
		LOWER(t.new_value) NOT IN (
			SELECT LOWER(Name) 
			FROM usr_access_roles
			WHERE ApplicationID = vr_application_id
		)

	UPDATE AR
		SET Title = REPLACE(REPLACE(t.title, N'ي', N'ی'), N'ك', N'ک')
	FROM vr_tbl AS t
		INNER JOIN usr_access_roles AS ar
		ON LOWER(ar.name) = LOWER(t.new_value)
	WHERE ar.application_id = vr_application_id
		
	UPDATE T
		SET UQID = ar.role_id
	FROM vr_tbl AS t
		INNER JOIN usr_access_roles AS ar
		ON LOWER(ar.name) = LOWER(t.new_value)
	WHERE ar.application_id = vr_application_id
	
	DELETE UGP
	FROM usr_user_group_permissions AS ugp
		INNER JOIN (
			SELECT	ROW_NUMBER() OVER 
						(PARTITION BY uar.group_id, t.uqid ORDER BY uar.role_id ASC) AS row_number,
					uar.group_id, 
					uar.role_id, 
					t.uqid
			FROM vr_tbl AS t
				INNER JOIN usr_user_group_permissions AS uar
				INNER JOIN usr_access_roles AS ar
				ON ar.application_id = vr_application_id AND ar.role_id = Uar.role_id
				ON uar.application_id = vr_application_id AND LOWER(ar.name) = LOWER(t.new_value)
		) AS r
		ON r.group_id = ugp.group_id AND r.role_id = ugp.role_id
	WHERE r.row_number > 1
	
	UPDATE UAR
		SET RoleID = t.uqid
	FROM vr_tbl AS t
		INNER JOIN usr_user_group_permissions AS uar
		INNER JOIN usr_access_roles AS ar
		ON ar.application_id = vr_application_id AND ar.role_id = Uar.role_id
		ON uar.application_id = vr_application_id AND LOWER(ar.name) = LOWER(t.new_value)

	DELETE usr_access_roles
	WHERE ApplicationID = vr_application_id AND 
		RoleID NOT IN (SELECT UQID FROM vr_tbl)
    
    RETURN 1
END;


DROP PROCEDURE IF EXISTS prvc_p_add_audience;

CREATE PROCEDURE prvc_p_add_audience
	vr_application_id		UUID,
	vr_object_id			UUID,
	vr_role_id				UUID,
	vr_permission_type		varchar(50),
	vr_allow			 BOOLEAN,
	vr_expiration_date	 TIMESTAMP,
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM prvc_audience
		WHERE ApplicationID = vr_application_id AND RoleID = vr_role_id AND ObjectID = vr_object_id
	) BEGIN
		UPDATE prvc_audience
			SET Allow = vr_allow,
				ExpirationDate = vr_expiration_date,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND ObjectID = vr_object_id AND 
			RoleID = vr_role_id AND PermissionType = vr_permission_type
	END
	ELSE BEGIN
		INSERT INTO prvc_audience(
			ApplicationID,
			ObjectID,
			RoleID,
			PermissionType,
			Allow,
			ExpirationDate,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_object_id, 
			vr_role_id, 
			vr_permission_type,
			vr_allow, 
			vr_expiration_date, 
			vr_creator_user_id, 
			vr_creation_date, 
			0
		)
	END
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS prvc_set_audience;

CREATE PROCEDURE prvc_set_audience
	vr_application_id			UUID,
	vr_object_idsTemp			GuidTableType readonly,
	vr_default_permissions_temp	GuidStringPairTableType readonly,
	vr_audienceTemp			PrivacyAudienceTableType readonly,
	vr_settingsTemp			GuidPairBitTableType readonly,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_object_ids GuidTableType
	INSERT INTO vr_object_ids SELECT * FROM vr_object_idsTemp
	
	DECLARE vr_default_permissions GuidStringPairTableType
	INSERT INTO vr_default_permissions SELECT * FROM vr_default_permissions_temp
	
	DECLARE vr_audience PrivacyAudienceTableType
	INSERT INTO vr_audience SELECT * FROM vr_audienceTemp
	
	DECLARE vr_settings GuidPairBitTableType
	INSERT INTO vr_settings SELECT * FROM vr_settingsTemp
	
	-- Update Settings
	DELETE S
	FROM vr_object_ids AS i_ds
		INNER JOIN prvc_settings AS s
		ON s.object_id = i_ds.value
		LEFT JOIN vr_settings AS t
		ON t.first_value = i_ds.value
	WHERE t.first_value IS NULL
	
	UPDATE S
		SET CalculateHierarchy = COALESCE(t.bit_value, FALSE),
			ConfidentialityID = t.second_value,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM prvc_settings AS s
		INNER JOIN vr_settings AS t
		ON t.first_value = s.object_id
	
	INSERT INTO prvc_settings (ApplicationID, ObjectID, 
		CalculateHierarchy, ConfidentialityID, CreatorUserID, CreationDate)
	SELECT vr_application_id, t.first_value, COALESCE(t.bit_value, FALSE), t.second_value, vr_current_user_id, vr_now
	FROM vr_settings AS t
		LEFT JOIN prvc_settings AS s
		ON s.object_id = t.first_value
	WHERE s.object_id IS NULL
	-- end of Update Settings
	
	
	-- Update Default Permissions
	DELETE P
	FROM vr_object_ids AS i_ds
		INNER JOIN prvc_default_permissions AS p
		ON p.object_id = i_ds.value
		LEFT JOIN vr_default_permissions AS d
		ON d.guid_value = i_ds.value AND d.first_value = p.permission_type
	WHERE d.guid_value IS NULL
	
	UPDATE P
		SET DefaultValue = d.second_value,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM prvc_default_permissions AS p
		INNER JOIN vr_default_permissions AS d
		ON d.guid_value = p.object_id AND d.first_value = p.permission_type
	
	INSERT INTO prvc_default_permissions (ApplicationID, ObjectID, 
		PermissionType, DefaultValue, CreatorUserID, CreationDate)
	SELECT vr_application_id, d.guid_value, d.first_value, d.second_value, vr_current_user_id, vr_now
	FROM vr_default_permissions AS d
		LEFT JOIN prvc_default_permissions AS p
		ON p.object_id = d.guid_value AND p.permission_type = d.first_value
	WHERE p.object_id IS NULL
	-- end of Update Default Permissions
	
	
	-- Update Audience
	UPDATE A
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_object_ids AS i_ds
		INNER JOIN prvc_audience AS a
		ON a.object_id = i_ds.value
		LEFT JOIN vr_audience AS d
		ON d.object_id = a.object_id AND d.role_id = a.role_id AND d.permission_type = a.permission_type
	WHERE d.object_id IS NULL
	
	UPDATE A
		SET Allow = COALESCE(d.allow, FALSE),
			PermissionType = d.permission_type,
			ExpirationDate = d.expiration_date,
		 deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM prvc_audience AS a
		INNER JOIN vr_audience AS d
		ON d.object_id = a.object_id AND d.role_id = a.role_id AND d.permission_type = a.permission_type
	
	INSERT INTO prvc_audience (ApplicationID, ObjectID, 
		RoleID, Allow, PermissionType, ExpirationDate, CreatorUserID, CreationDate, Deleted)
	SELECT vr_application_id, d.object_id, d.role_id, COALESCE(d.allow, FALSE), 
		d.permission_type, d.expiration_date, vr_current_user_id, vr_now, 0
	FROM vr_audience AS d
		LEFT JOIN prvc_audience AS a
		ON a.object_id = d.object_id AND a.role_id = d.role_id AND d.permission_type = a.permission_type
	WHERE a.object_id IS NULL
	-- end of Update Audience
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS prvc_check_access;

CREATE PROCEDURE prvc_check_access
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_object_type			varchar(50),
    vr_object_idsTemp		GuidTableType readonly,
    vr_permissions_temp	StringPairTableType readonly,
    vr_now			 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_object_ids GuidTableType
	INSERT INTO vr_object_ids SELECT DISTINCT * FROM vr_object_idsTemp
	
    DECLARE vr_permissions StringPairTableType
    INSERT INTO vr_permissions SELECT * FROM vr_permissions_temp
	
	DECLARE vr_iDs KeyLessGuidTableType
	
	INSERT INTO vr_iDs (Value)
	SELECT o.value
	FROM vr_object_ids AS o
	
	SELECT ref.id, ref.type
	FROM prvc_fn_check_access(vr_application_id, vr_user_id, 
		vr_iDs, vr_object_type, vr_now, vr_permissions) AS ref
END;


DROP PROCEDURE IF EXISTS prvc_get_audience_role_ids;

CREATE PROCEDURE prvc_get_audience_role_ids
	vr_application_id	UUID,
	vr_object_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ref.role_id AS id
	FROM prvc_audience AS ref
	WHERE ref.application_id = vr_application_id AND ref.object_id = vr_object_id AND ref.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS prvc_get_audience;

CREATE PROCEDURE prvc_get_audience
	vr_application_id	UUID,
	vr_strObjectIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_object_ids GuidTableType
	
	INSERT INTO vr_object_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strObjectIDs, vr_delimiter) AS ref
	
	DECLARE vr_audience Table(ObjectID UUID, RoleID UUID, 
		PermissionType varchar(50), Allow BOOLEAN, ExpirationDate TIMESTAMP)
	
	INSERT INTO vr_audience (ObjectID, RoleID, PermissionType, Allow, ExpirationDate)
	SELECT ref.object_id, ref.role_id, ref.permission_type, ref.allow, ref.expiration_date
	FROM vr_object_ids AS i_ds
		INNER JOIN prvc_audience AS ref
		ON ref.application_id = vr_application_id AND ref.object_id = i_ds.value AND ref.deleted = FALSE

	SELECT	external_ids.*,
			RTRIM(LTRIM((COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS name,
			N'User' AS type,
			NULL AS node_type,
			un.username AS additional_id
	FROM vr_audience AS external_ids
		INNER JOIN users_normal AS un
		ON un.user_id = external_ids.role_id
	WHERE un.application_id = vr_application_id AND un.is_approved = TRUE
	
	UNION ALL
	
	SELECT	external_ids.*,
			nd.node_name AS name,
			N'Node' AS type,
			nd.type_name AS node_type,
			nd.node_additional_id AS additional_id
	FROM vr_audience AS external_ids
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.node_id = external_ids.role_id
	WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS prvc_get_default_permissions;

CREATE PROCEDURE prvc_get_default_permissions
	vr_application_id	UUID,
	vr_strObjectIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_object_ids GuidTableType
	
	INSERT INTO vr_object_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strObjectIDs, vr_delimiter) AS ref
	
	SELECT p.object_id AS id, p.permission_type AS type, p.default_value
	FROM vr_object_ids AS i_ds
		INNER JOIN prvc_default_permissions AS p
		ON p.application_id = vr_application_id AND p.object_id = i_ds.value
END;


DROP PROCEDURE IF EXISTS prvc_get_settings;

CREATE PROCEDURE prvc_get_settings
	vr_application_id	UUID,
	vr_strObjectIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_object_ids GuidTableType
	
	INSERT INTO vr_object_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strObjectIDs, vr_delimiter) AS ref
	
	SELECT i_ds.value AS object_id, s.calculate_hierarchy, s.confidentiality_id, cl.level_id, cl.title AS level
	FROM vr_object_ids AS i_ds
		LEFT JOIN prvc_settings AS s
		ON s.application_id = vr_application_id AND s.object_id = i_ds.value
		LEFT JOIN prvc_confidentiality_levels AS cl
		ON cl.application_id = vr_application_id AND cl.id = s.confidentiality_id AND cl.deleted = FALSE
END;


-- Confidentiality

DROP PROCEDURE IF EXISTS prvc_add_confidentiality_level;

CREATE PROCEDURE prvc_add_confidentiality_level
	vr_application_id	UUID,
	vr_iD				UUID,
	vr_level_id	 INTEGER,
	vr_title		 VARCHAR(256),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM prvc_confidentiality_levels 
		WHERE ApplicationID = vr_application_id AND LevelID = vr_level_id AND deleted = FALSE
	) BEGIN
		SELECT -1, N'LevelCodeAlreadyExists'
		RETURN
	END
	
	INSERT INTO prvc_confidentiality_levels(
		ApplicationID,
		ID,
		LevelID,
		Title,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_iD,
		vr_level_id,
		vr_title,
		vr_current_user_id,
		vr_now,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS prvc_modify_confidentiality_level;

CREATE PROCEDURE prvc_modify_confidentiality_level
	vr_application_id	UUID,
	vr_iD				UUID,
	vr_new_level_id	 INTEGER,
	vr_new_title	 VARCHAR(256),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_new_title = gfn_verify_string(vr_new_title)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM prvc_confidentiality_levels 
		WHERE ApplicationID = vr_application_id AND 
			ID <> vr_iD AND LevelID = vr_new_level_id AND deleted = FALSE
	) BEGIN
		SELECT -1, N'LevelCodeAlreadyExists'
		RETURN
	END
	
	UPDATE prvc_confidentiality_levels
		SET LevelID = vr_new_level_id,
			Title = vr_new_title,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS prvc_remove_confidentiality_level;

CREATE PROCEDURE prvc_remove_confidentiality_level
	vr_application_id	UUID,
	vr_iD				UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE prvc_confidentiality_levels
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS prvc_get_confidentiality_levels;

CREATE PROCEDURE prvc_get_confidentiality_levels
	vr_application_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT conf.id AS id,
		   conf.level_id AS level_id,
		   conf.title AS title
	FROM prvc_confidentiality_levels AS conf
	WHERE conf.application_id = vr_application_id AND conf.deleted = FALSE
	ORDER BY conf.level_id ASC
END;


DROP PROCEDURE IF EXISTS prvc_set_confidentiality_level;

CREATE PROCEDURE prvc_set_confidentiality_level
	vr_application_id			UUID,
	vr_itemID					UUID,
	vr_level_id				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM prvc_settings 
		WHERE ApplicationID = vr_application_id AND ObjectID = vr_itemID
	) BEGIN
		UPDATE prvc_settings
			SET ConfidentialityID = vr_level_id,
				LastModifierUserID = vr_last_modifier_user_id,
				LastModificationDate = vr_last_modification_date
		WHERE ApplicationID = vr_application_id AND ObjectID = vr_itemID
	END
	ELSE BEGIN
		INSERT INTO prvc_settings(
			ApplicationID,
			ObjectID,
			ConfidentialityID,
			CreatorUserID,
			CreationDate
		)
		VALUES(
			vr_application_id,
			vr_itemID,
			vr_level_id,
			vr_last_modifier_user_id,
			vr_last_modification_date
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS prvc_unset_confidentiality_level;

CREATE PROCEDURE prvc_unset_confidentiality_level
	vr_application_id			UUID,
	vr_itemID					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE prvc_settings
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
			ConfidentialityID = null
	WHERE ApplicationID = vr_application_id AND ObjectID = vr_itemID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS prvc_get_confidentiality_level_user_ids;

CREATE PROCEDURE prvc_get_confidentiality_level_user_ids
	vr_application_id			UUID,
	vr_confidentiality_id		UUID,
	vr_searchText			 VARCHAR(500),
	vr_count				 INTEGER,
	vr_lower_boundary			bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE(vr_count, 0) <= 0 SET vr_count = 1000000
	
	IF COALESCE(vr_searchText, N'') = N'' BEGIN
		SELECT TOP(vr_count)
			ref.user_id,
			(ref.row_number + ref.rev_row_number - 1) AS total_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY usr.user_id DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY usr.user_id ASC) AS rev_row_number,
						usr.user_id
				FROM prvc_view_confidentialities AS c
					INNER JOIN users_normal AS usr
					ON usr.application_id = vr_application_id AND usr.user_id = c.object_id
				WHERE c.application_id = vr_application_id AND c.confidentiality_id = vr_confidentiality_id
			) AS ref
		WHERE ref.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY ref.row_number ASC
	END
	ELSE BEGIN
		SELECT TOP(vr_count)
			ref.user_id,
			(ref.row_number + ref.rev_row_number - 1) AS total_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, usr.user_id DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, usr.user_id ASC) AS rev_row_number,
						usr.user_id
				FROM CONTAINSTABLE(usr_view_users, (FirstName, LastName, UserName), vr_searchText) AS srch 
					INNER JOIN prvc_view_confidentialities AS c
					INNER JOIN users_normal AS usr
					ON usr.application_id = vr_application_id AND usr.user_id = c.object_id
					ON usr.user_id = srch.key
				WHERE c.application_id = vr_application_id AND c.confidentiality_id = vr_confidentiality_id
			) AS ref
		WHERE ref.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY ref.row_number ASC	
	END
END;

-- end of Confidentiality

DROP PROCEDURE IF EXISTS fg_p_create_form;

CREATE PROCEDURE fg_p_create_form
	vr_application_id		UUID,
    vr_form_id				UUID,
    vr_template_form_id		UUID,
	vr_title			 VARCHAR(255),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__ret_val INTEGER
	SET vr__ret_val = 0
	
	SET vr_title = gfn_verify_string(vr_title)
	
	IF EXISTS (
		SELECT TOP(1) * 
		FROM fg_extended_forms
		WHERE ApplicationID = vr_application_id AND Title = vr_title AND deleted = TRUE
	) BEGIN
			UPDATE fg_extended_forms
			SET TemplateFormID = vr_template_form_id,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
			WHERE ApplicationID = vr_application_id AND Title = vr_title AND deleted = TRUE
			
		SET vr__ret_val = @vr_rowcount
	END
	ELSE IF EXISTS (
		SELECT TOP(1) * 
		FROM fg_extended_forms
		WHERE ApplicationID = vr_application_id AND Title = vr_title AND deleted = FALSE
	) BEGIN
			SET vr__ret_val = -1
	END	
	ELSE BEGIN
		INSERT INTO fg_extended_forms(
			ApplicationID,
			FormID,
			TemplateFormID,
			Title,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_form_id,
			vr_template_form_id,
			vr_title,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
		SET vr__ret_val = @vr_rowcount
	END
	
	IF (@vr_rowcount <= 0 AND vr__ret_val = 0) BEGIN
		SET vr__result = vr__ret_val
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SET vr__result = vr__ret_val
	
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS fg_create_form;

CREATE PROCEDURE fg_create_form
	vr_application_id		UUID,
    vr_form_id				UUID,
    vr_template_form_id		UUID,
	vr_title			 VARCHAR(255),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC fg_p_create_form vr_application_id, vr_form_id, vr_template_form_id,
		vr_title, vr_creator_user_id, vr_creation_date, vr__result output
		
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_set_form_title;

CREATE PROCEDURE fg_set_form_title
	vr_application_id			UUID,
    vr_form_id					UUID,
    vr_title				 VARCHAR(255),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS (
		SELECT TOP(1) * 
		FROM fg_extended_forms
		WHERE ApplicationID = vr_application_id AND Title = vr_title AND FormID <> vr_form_id AND deleted = FALSE
	) BEGIN
		SELECT -1
		RETURN
	END
	
	UPDATE fg_extended_forms
		SET Title = gfn_verify_string(vr_title),
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_name;

CREATE PROCEDURE fg_set_form_name
	vr_application_id	UUID,
    vr_form_id			UUID,
    vr_name			varchar(100),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE(vr_name, N'') <> N'' AND EXISTS(
		SELECT TOP(1) *
		FROM fg_extended_forms AS f
		WHERE f.application_id = vr_application_id AND f.deleted = FALSE AND 
			LOWER(f.name) = LOWER(vr_name) AND f.form_id <> vr_form_id
	) BEGIN
		SELECT -1, N'NameAlreadyExists'
		RETURN
	END
	
	UPDATE fg_extended_forms
		SET Name = vr_name,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_description;

CREATE PROCEDURE fg_set_form_description
	vr_application_id			UUID,
    vr_form_id					UUID,
    vr_description		 VARCHAR(2000),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_extended_forms
		SET description = vr_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_arithmetic_delete_form;

CREATE PROCEDURE fg_arithmetic_delete_form
	vr_application_id			UUID,
    vr_form_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_extended_forms
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_recycle_form;

CREATE PROCEDURE fg_recycle_form
	vr_application_id			UUID,
    vr_form_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_extended_forms
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = FALSE
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_p_get_forms_by_ids;

CREATE PROCEDURE fg_p_get_forms_by_ids
	vr_application_id	UUID,
    vr_form_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_ids GuidTableType
	INSERT INTO vr_form_ids SELECT * FROM vr_form_idsTemp
	
	SELECT ef.form_id,
		   ef.title,
		   ef.name,
		   ef.description
	FROM vr_form_ids AS external_ids
		INNER JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = external_ids.value
	ORDER BY ef.creation_date DESC
END;


DROP PROCEDURE IF EXISTS fg_get_forms_by_ids;

CREATE PROCEDURE fg_get_forms_by_ids
	vr_application_id	UUID,
    vr_strFormIDs		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_ids GuidTableType
	INSERT INTO vr_form_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strFormIDs, vr_delimiter) AS ref
	
	EXEC fg_p_get_forms_by_ids vr_application_id, vr_form_ids
END;


DROP PROCEDURE IF EXISTS fg_get_forms;

CREATE PROCEDURE fg_get_forms
	vr_application_id	UUID,
	vr_searchText	 VARCHAR(1000),
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER,
	vr_has_name	 BOOLEAN,
	vr_archive	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_archive = COALESCE(vr_archive, 0)
	
	DECLARE vr_form_ids GuidTableType
	
	IF COALESCE(vr_searchText, N'') = N'' BEGIN
		INSERT INTO vr_form_ids (Value)
		SELECT TOP(COALESCE(vr_count, 1000000)) x.form_id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY f.form_id ASC) AS row_number,
						f.form_id 
				FROM fg_extended_forms AS f
				WHERE f.application_id = vr_application_id AND f.deleted = vr_archive AND
					(vr_has_name IS NULL OR (vr_has_name = 0 AND COALESCE(f.name, N'') = N'') OR 
						(vr_has_name = 1 AND COALESCE(f.name, N'') <> N''))
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
	ELSE BEGIN
		INSERT INTO vr_form_ids (Value)
		SELECT TOP(COALESCE(vr_count, 1000000)) x.form_id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, f.form_id ASC) AS row_number,
						f.form_id 
				FROM CONTAINSTABLE(fg_extended_forms, (Title), vr_searchText) AS srch
					INNER JOIN fg_extended_forms AS f
					ON f.application_id = vr_application_id AND f.form_id = srch.key AND
						f.deleted = vr_archive AND
						(vr_has_name IS NULL OR (vr_has_name = 0 AND COALESCE(f.name, N'') = N'') OR 
							(vr_has_name = 1 AND COALESCE(f.name, N'') <> N''))
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
	
	EXEC fg_p_get_forms_by_ids vr_application_id, vr_form_ids
END;


DROP PROCEDURE IF EXISTS fg_add_form_element;

CREATE PROCEDURE fg_add_form_element
	vr_application_id		UUID,
	vr_element_id			UUID,
	vr_template_element_id	UUID,
	vr_form_id				UUID,
	vr_title			 VARCHAR(2000),
	vr_name				varchar(100),
	vr_help			 VARCHAR(2000),
	vr_sequenceNumber	 INTEGER,
	vr_type				varchar(20),
	vr_info			 VARCHAR(max),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE(vr_name, N'') <> N'' AND EXISTS(
		SELECT TOP(1) *
		FROM fg_extended_form_elements AS f
		WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id AND 
			f.deleted = FALSE AND LOWER(f.name) = LOWER(vr_name)
	) BEGIN
		SELECT -1, N'NameAlreadyExists'
		RETURN
	END
	
	INSERT INTO fg_extended_form_elements(
		ApplicationID,
		ElementID,
		TemplateElementID,
		FormID,
		Title,
		Name,
		Help,
		SequenceNumber,
		type,
		Info,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_element_id,
		vr_template_element_id,
		vr_form_id,
		gfn_verify_string(vr_title),
		vr_name,
		gfn_verify_string(vr_help),
		vr_sequenceNumber,
		vr_type,
		vr_info,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_modify_form_element;

CREATE PROCEDURE fg_modify_form_element
	vr_application_id			UUID,
	vr_element_id				UUID,
	vr_title				 VARCHAR(2000),
	vr_name					varchar(100),
	vr_help				 VARCHAR(2000),
	vr_info				 VARCHAR(max),
	vr_weight					float,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_id UUID = (
		SELECT TOP(1) FormID
		FROM fg_extended_form_elements AS e
		WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id
	)
	
	IF COALESCE(vr_name, N'') <> N'' AND EXISTS(
		SELECT TOP(1) *
		FROM fg_extended_form_elements AS f
		WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id AND f.deleted = FALSE AND 
			LOWER(f.name) = LOWER(vr_name) AND f.element_id <> vr_element_id
	) BEGIN
		SELECT -1, N'NameAlreadyExists'
		RETURN
	END
	
	UPDATE fg_extended_form_elements
		SET Title = gfn_verify_string(vr_title),
			Name = vr_name,
			Help = gfn_verify_string(vr_help),
			Info = vr_info,
			weight = vr_weight,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND ElementID = vr_element_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_elements_order;

CREATE PROCEDURE fg_set_elements_order
	vr_application_id	UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids TABLE (SequenceNo INTEGER identity(1, 1) primary key, ElementID UUID)
	
	INSERT INTO vr_element_ids (ElementID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_form_id UUID
	
	SELECT vr_form_id = FormID
	FROM fg_extended_form_elements
	WHERE ApplicationID = vr_application_id AND 
		ElementID = (SELECT TOP (1) ref.element_id FROM vr_element_ids AS ref)
	
	IF vr_form_id IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO vr_element_ids (ElementID)
	SELECT e.element_id
	FROM vr_element_ids AS ref
		RIGHT JOIN fg_extended_form_elements AS e
		ON e.element_id = ref.element_id
	WHERE e.application_id = vr_application_id AND e.form_id = vr_form_id AND ref.element_id IS NULL
	ORDER BY e.sequence_number
	
	UPDATE fg_extended_form_elements
		SET SequenceNumber = ref.sequence_no
	FROM vr_element_ids AS ref
		INNER JOIN fg_extended_form_elements AS e
		ON e.element_id = ref.element_id
	WHERE e.application_id = vr_application_id AND e.form_id = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_element_necessity;

CREATE PROCEDURE fg_set_form_element_necessity
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_necessity	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_extended_form_elements
		SET Necessary = vr_necessity
	WHERE ApplicationID = vr_application_id AND ElementID = vr_element_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_element_uniqueness;

CREATE PROCEDURE fg_set_form_element_uniqueness
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_value		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_extended_form_elements
		SET UniqueValue = vr_value
	WHERE ApplicationID = vr_application_id AND ElementID = vr_element_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_arithmetic_delete_form_element;

CREATE PROCEDURE fg_arithmetic_delete_form_element
	vr_application_id			UUID,
	vr_element_id				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_extended_form_elements
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ElementID = vr_element_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_save_form_elements;

CREATE PROCEDURE fg_save_form_elements
	vr_application_id	UUID,
	vr_form_id			UUID,
	vr_title		 VARCHAR(255),
	vr_name			varchar(100),
	vr_description VARCHAR(2000),
	vr_elementsTemp	FormElementTableType readonly,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_elements FormElementTableType
	INSERT INTO vr_elements SELECT * FROM vr_elementsTemp
	
	-- Update Form
	SET vr_title = gfn_verify_string(LTRIM(RTRIM(COALESCE(vr_title, N''))))
	SET vr_name = LTRIM(RTRIM(COALESCE(vr_name, '')))
	SET vr_description = gfn_verify_string(LTRIM(RTRIM(COALESCE(vr_description, N''))))
	
	UPDATE fg_extended_forms
		SET Title = CASE WHEN vr_title = N'' THEN Title ELSE vr_title END,
			Name = CASE WHEN vr_name = N'' THEN Name ELSE vr_name END,
			description = CASE WHEN vr_description = N'' THEN description ELSE vr_description END
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id
	-- end of Update Form
	
	
	-- Update Existing Data
	UPDATE X
		SET	Title = CASE WHEN e.element_id IS NULL THEN x.title ELSE e.title END,
			Info = CASE WHEN e.element_id IS NULL THEN x.info ELSE e.info END,
			SequenceNumber = CASE WHEN e.element_id IS NULL THEN x.sequence_number ELSE e.sequence_nubmer END,
			LastModifierUserID = CASE WHEN e.element_id IS NULL THEN x.last_modifier_user_id ELSE vr_current_user_id END,
			LastModificationDate = CASE WHEN e.element_id IS NULL THEN x.last_modification_date ELSE vr_now END,
			Deleted = CASE WHEN e.element_id IS NULL THEN 1 ELSE 0 END,
			Necessary = CASE WHEN e.element_id IS NULL THEN x.necessary ELSE e.necessary END,
			weight = CASE WHEN e.element_id IS NULL THEN x.weight ELSE e.weight END,
			Name = CASE WHEN e.element_id IS NULL THEN x.name ELSE e.name END,
			UniqueValue = CASE WHEN e.element_id IS NULL THEN x.unique_value ELSE e.unique_value END,
			Help = CASE WHEN e.element_id IS NULL THEN x.help ELSE e.help END
	FROM fg_extended_form_elements AS x
		LEFT JOIN vr_elements AS e
		ON e.element_id = x.element_id
	WHERE x.application_id = vr_application_id AND x.form_id = vr_form_id
	-- end of Update Existing Data
	
	-- Insert New Data
	INSERT INTO fg_extended_form_elements (
		ApplicationID,
		ElementID,
		TemplateElementID,
		FormID,
		Title,
		type,
		Info,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted,
		Necessary,
		weight,
		Name,
		UniqueValue,
		Help
	)
	SELECT	vr_application_id,
			e.element_id,
			e.template_element_id,
			vr_form_id,
			e.title,
			e.type,
			e.info,
			e.sequence_nubmer,
			vr_current_user_id,
			vr_now,
			0,
			e.necessary,
			e.weight,
			e.name,
			e.unique_value,
			e.help
	FROM vr_elements AS e
		LEFT JOIN fg_extended_form_elements AS x
		ON x.application_id = vr_application_id AND x.element_id = e.element_id
	WHERE x.element_id IS NULL
	-- end of Insert New Data
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS fg_p_get_form_elements;

CREATE PROCEDURE fg_p_get_form_elements
	vr_application_id	UUID,
	vr_element_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	INSERT INTO vr_element_ids SELECT * FROM vr_element_idsTemp
	
	SELECT fe.element_id,
		   fe.form_id,
		   fe.title,
		   fe.name,
		   fe.help,
		   COALESCE(fe.necessary, CAST(0 AS boolean)) AS necessary,
		   COALESCE(fe.unique_value, CAST(0 AS boolean)) AS unique_value,
		   fe.sequence_number,
		   fe.type,
		   fe.info,
		   fe.weight
	FROM vr_element_ids AS ref
		INNER JOIN fg_extended_form_elements AS fe
		ON fe.application_id = vr_application_id AND fe.element_id = ref.value
	ORDER BY fe.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS fg_get_form_elements_by_ids;

CREATE PROCEDURE fg_get_form_elements_by_ids
	vr_application_id	UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	EXEC fg_p_get_form_elements vr_application_id, vr_element_ids
END;


DROP PROCEDURE IF EXISTS fg_get_form_elements;

CREATE PROCEDURE fg_get_form_elements	
	vr_application_id	UUID,
	vr_form_id			UUID,
	vr_owner_id		UUID,
	vr_type			varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_form_id IS NULL AND vr_owner_id IS NOT NULL BEGIN
		SELECT TOP(1) vr_form_id = FormID
		FROM fg_form_owners 
		WHERE ApplicationID = vr_application_id AND 
			OwnerID = vr_owner_id AND deleted = FALSE
	END
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids
	SELECT ElementID
	FROM fg_extended_form_elements
	WHERE ApplicationID = vr_application_id AND FormID = vr_form_id AND 
		(vr_type IS NULL OR type = vr_type) AND deleted = FALSE
	
	EXEC fg_p_get_form_elements vr_application_id, vr_element_ids
END;


DROP PROCEDURE IF EXISTS fg_get_form_element_ids;

CREATE PROCEDURE fg_get_form_element_ids	
	vr_application_id		UUID,
	vr_form_id				UUID,
	vr_strElementNames VARCHAR(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_names StringTableType
	
	INSERT INTO vr_names (Value)
	SELECT DISTINCT LOWER(ref.value)
	FROM gfn_str_to_string_table(vr_strElementNames, vr_delimiter) AS ref
	WHERE COALESCE(ref.value, N'') <> N''
	
	SELECT e.name, e.element_id
	FROM vr_names AS n
		INNER JOIN fg_extended_form_elements AS e
		ON e.application_id = vr_application_id AND e.form_id = vr_form_id AND 
			LOWER(COALESCE(e.name, N'')) = n.value
END;


DROP PROCEDURE IF EXISTS fg_is_form_element;

CREATE PROCEDURE fg_is_form_element
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ref.value AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
		INNER JOIN fg_extended_form_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = ref.value
		
	UNION
	
	SELECT ref.value AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
		INNER JOIN fg_instance_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = ref.value
END;


DROP PROCEDURE IF EXISTS fg_p_create_form_instance;

CREATE PROCEDURE fg_p_create_form_instance
	vr_application_id	UUID,
	vr_instancesTemp	FormInstanceTableType readonly,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instances FormInstanceTableType
	INSERT INTO vr_instances SELECT * FROM vr_instancesTemp
	
	INSERT INTO fg_form_instances(
		ApplicationID,
		InstanceID,
		FormID,
		OwnerID,
		DirectorID,
		admin,
		Filled,
		IsTemporary,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	vr_application_id, 
			i.instance_id, 
			i.form_id, 
			i.owner_id, 
			i.director_id, 
			COALESCE(i.admin, FALSE), 
			0,
			i.is_temporary,
			vr_creator_user_id, 
			vr_creation_date, 
			0
	FROM vr_instances AS i
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_create_form_instance;

CREATE PROCEDURE fg_create_form_instance
	vr_application_id	UUID,
	vr_instancesTemp	FormInstanceTableType readonly,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instances FormInstanceTableType
	INSERT INTO vr_instances SELECT * FROM vr_instancesTemp
	
	DECLARE vr__result INTEGER
	
	EXEC fg_p_create_form_instance vr_application_id, vr_instances, vr_creator_user_id, vr_creation_date, vr__result output
		
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_p_copy_form_instances;

CREATE PROCEDURE fg_p_copy_form_instances
	vr_application_id	UUID,
	vr_old_owner_id		UUID,
	vr_new_owner_id		UUID,
	vr_new_form_id		UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM fg_form_instances
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_old_owner_id AND deleted = FALSE
	) BEGIN
		INSERT INTO fg_form_instances(
			ApplicationID,
			InstanceID,
			FormID,
			OwnerID,
			DirectorID,
			Filled,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT	vr_application_id,
				gen_random_uuid(),
				COALESCE(vr_new_form_id, FormID),
				vr_new_owner_id,
				DirectorID,
				0,
				vr_creator_user_id,
				vr_creation_date,
				0
		FROM fg_form_instances
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_old_owner_id AND deleted = FALSE
		
		SET vr__result = @vr_rowcount	
	END
	ELSE
		SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS fg_p_remove_form_instances;

CREATE PROCEDURE fg_p_remove_form_instances
	vr_application_id		UUID,
	vr_instanceIDsTemp	GuidTableType readonly,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs SELECT * FROM vr_instanceIDsTemp
	
	UPDATE FI
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_instanceIDs AS external_ids
		INNER JOIN fg_form_instances AS fi
		ON fi.instance_id = external_ids.value
	WHERE fi.application_id = vr_application_id AND fi.deleted = FALSE
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_remove_form_instances;

CREATE PROCEDURE fg_remove_form_instances
	vr_application_id	UUID,
	vr_strInstanceIDs	varchar(max),
	vr_delimiter		char,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strInstanceIDs, vr_delimiter) AS ref
	
	DECLARE vr__result INTEGER = 0
	
	EXEC fg_p_remove_form_instances vr_application_id, vr_instanceIDs, vr_current_user_id, vr_now, vr__result output 
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_remove_owner_form_instances;

CREATE PROCEDURE fg_remove_owner_form_instances
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	
	INSERT INTO vr_instanceIDs (Value)
	SELECT i.instance_id
	FROM fg_form_instances AS i
	WHERE i.application_id = vr_application_id AND i.form_id = vr_form_id AND 
		i.owner_id = vr_owner_id AND i.deleted = FALSE
	
	DECLARE vr__result INTEGER = 0
	
	EXEC fg_p_remove_form_instances vr_application_id, vr_instanceIDs, vr_current_user_id, vr_now, vr__result output 
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_p_get_form_instances_by_ids;

CREATE PROCEDURE fg_p_get_form_instances_by_ids
	vr_application_id		UUID,
	vr_instanceIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs SELECT * FROM vr_instanceIDsTemp
	
	SELECT fi.instance_id AS instance_id,
		   fi.form_id AS form_id,
		   fi.owner_id AS owner_id,
		   fi.director_id AS director_id,
		   fi.filled AS filled,
		   fi.filling_date AS filling_date,
		   ef.title AS form_title,
		   ef.description AS description,
		   fi.creator_user_id AS creator_user_id,
		   un.username AS creator_username,
		   un.first_name AS creator_first_name,
		   un.last_name AS creator_last_name
	FROM vr_instanceIDs AS external_ids
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = external_ids.value
		INNER JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = fi.form_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = fi.creator_user_id
END;


DROP PROCEDURE IF EXISTS fg_p_get_owner_form_instances;

CREATE PROCEDURE fg_p_get_owner_form_instances
	vr_application_id	UUID,
	vr_owner_idsTemp	GuidTableType readonly,
	vr_form_id			UUID,
	vr_isTemporary BOOLEAN,
	vr_creator_user_id	UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids SELECT * FROM vr_owner_idsTemp
	
	DECLARE vr_instanceIDs GuidTableType
	
	INSERT INTO vr_instanceIDs
	SELECT x.instance_id
	FROM fg_fn_get_owner_form_instance_ids(vr_application_id, vr_owner_ids, vr_form_id, vr_isTemporary, vr_creator_user_id) AS x
	
	EXEC fg_p_get_form_instances_by_ids vr_application_id, vr_instanceIDs
END;


DROP PROCEDURE IF EXISTS fg_get_owner_form_instances;

CREATE PROCEDURE fg_get_owner_form_instances
	vr_application_id	UUID,
	vr_strOwnerIDs	varchar(max),
	vr_delimiter		char,
	vr_form_id			UUID,
	vr_isTemporary BOOLEAN,
	vr_creator_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strOwnerIDs, vr_delimiter) AS ref
	
	EXEC fg_p_get_owner_form_instances vr_application_id, vr_owner_ids, vr_form_id, vr_isTemporary, vr_creator_user_id
END;


DROP PROCEDURE IF EXISTS fg_get_form_instance_owner_id;

CREATE PROCEDURE fg_get_form_instance_owner_id
	vr_application_id			UUID,
	vr_instanceIDOrElementID	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_id UUID
	
	SELECT TOP(1) vr_owner_id = fi.owner_id
	FROM fg_form_instances AS fi
	WHERE fi.application_id = vr_application_id AND 
		fi.instance_id = vr_instanceIDOrElementID
	
	IF vr_owner_id IS NULL BEGIN
		SELECT TOP(1) vr_owner_id = fi.owner_id
		FROM fg_instance_elements AS ie
			INNER JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.instance_id = ie.instance_id
		WHERE ie.application_id = vr_application_id AND 
			ie.element_id = vr_instanceIDOrElementID
	END
	
	SELECT vr_owner_id
END;


DROP PROCEDURE IF EXISTS fg_get_form_instance_hierarchy_owner_id;

CREATE PROCEDURE fg_get_form_instance_hierarchy_owner_id
	vr_application_id	UUID,
	vr_instanceID		UUID
WITH ENCRYPTION
AS
BEGIN
	WITH hierarchy (OwnerID, level)
 AS 
	(
		SELECT i.owner_id, 0 AS level
		FROM fg_form_instances AS i
		WHERE i.application_id = vr_application_id AND i.instance_id = vr_instanceID
		
		UNION ALL
		
		SELECT i.owner_id, level + 1
		FROM hierarchy AS hr
			INNER JOIN fg_instance_elements AS e
			ON e.application_id = vr_application_id AND e.element_id = hr.owner_id
			INNER JOIN fg_form_instances AS i
			ON i.application_id = vr_application_id AND i.instance_id = e.instance_id
		WHERE hr.owner_id IS NOT NULL AND i.owner_id <> hr.owner_id
	)

	SELECT TOP(1) hr.owner_id AS id
	FROM hierarchy AS hr
		INNER JOIN (
			SELECT TOP(1) MAX(level) AS level
			FROM hierarchy
		) AS a
		ON a.level = hr.level
END;


DROP PROCEDURE IF EXISTS fg_validate_new_name;

CREATE PROCEDURE fg_validate_new_name
	vr_application_id	UUID,
	vr_object_id		UUID,
	vr_form_id			UUID,
	vr_name			varchar(100)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT fg_fn_validate_new_name(vr_application_id, vr_object_id, vr_form_id, vr_name) AS value
END;


DROP PROCEDURE IF EXISTS fg_meets_unique_constraint;

CREATE PROCEDURE fg_meets_unique_constraint
	vr_application_id	UUID,
	vr_instanceID		UUID,
	vr_element_id		UUID,
	vr_textValue	 VARCHAR(max),
	vr_float_value		float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_ref_element_id UUID = (
		SELECT TOP(1) e.ref_element_id
		FROM fg_instance_elements AS e
		WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id
	)
	
	DECLARE vr_elements FormElementTableType
	
	INSERT INTO vr_elements (ElementID, InstanceID, RefElementID, TextValue, FloatValue, SequenceNubmer, type)
	SELECT vr_element_id, vr_instanceID, vr_ref_element_id, vr_textValue, vr_float_value, 0, N''
	
	SELECT TOP(1) 1
	WHERE vr_instanceID IS NOT NULL AND ((COALESCE(vr_textValue, N'') = N'' AND vr_float_value IS NULL) OR NOT EXISTS (
			SELECT TOP(1) x.element_id
			FROM fg_fn_check_unique_constraint(vr_application_id, vr_elements) AS x
		))
END;


DROP PROCEDURE IF EXISTS fg_save_form_instance_elements;

CREATE PROCEDURE fg_save_form_instance_elements
	vr_application_id			UUID,
	vr_elementsTemp			FormElementTableType readonly,
	vr_guid_itemsTemp			GuidPairTableType readonly,
	vr_elementsToClearTemp	GuidTableType readonly,
	vr_filesTemp				DocFileInfoTableType readonly,
	vr_creator_user_id			UUID,
	vr_creation_date		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_elements FormElementTableType
	INSERT INTO vr_elements SELECT * FROM vr_elementsTemp
	
	DECLARE vr_guid_items GuidPairTableType
	INSERT INTO vr_guid_items SELECT * FROM vr_guid_itemsTemp
	
	DECLARE vr_elementsToClear GuidTableType
	INSERT INTO vr_elementsToClear SELECT * FROM vr_elementsToClearTemp
	
	DECLARE vr_files DocFileInfoTableType
	INSERT INTO vr_files SELECT * FROM vr_filesTemp
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM fg_fn_check_unique_constraint(vr_application_id, vr_elements) AS ref
	) BEGIN
		SELECT -1, N'UniqueConstriantHasNotBeenMet'
		RETURN
	END
	
	-- Find Main ElementIDs
	DECLARE vr_main_element_ids TABLE (ElementID UUID, MainElementID UUID)
	
	INSERT INTO vr_main_element_ids (ElementID, MainElementID)
	SELECT DISTINCT ref.element_id, ie1.element_id
	FROM vr_elements AS ref
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = ref.element_id
		INNER JOIN fg_instance_elements AS ie1
		ON ie1.application_id = vr_application_id AND
			ref.ref_element_id IS NOT NULL AND ref.instance_id IS NOT NULL AND
			ie1.ref_element_id = ref.ref_element_id AND ie1.instance_id = ref.instance_id
	WHERE ie.element_id IS NULL
	
	/*
	UPDATE E
		SET ElementID = m.main_element_id
	FROM vr_elements AS e
		INNER JOIN vr_main_element_ids AS m
		ON m.element_id = e.element_id
	*/
		
	UPDATE E
		SET FirstValue = m.main_element_id
	FROM vr_guid_items AS e
		INNER JOIN vr_main_element_ids AS m
		ON m.element_id = e.first_value
	-- end of Find Main ElementIDs
	
	
	-- Save Changes
	INSERT INTO fg_changes (ApplicationID, ElementID, TextValue, 
		FloatValue, BitValue, DateValue, CreatorUserID, CreationDate, Deleted)
	SELECT vr_application_id, COALESCE(e.element_id, x.element_id), gfn_verify_string(x.text_value), 
		x.float_value, x.bit_value, x.date_value, vr_creator_user_id, vr_creation_date, 0
	FROM (
			SELECT	c.value AS element_id, 
					i.ref_element_id AS ref_element_id,
					i.instance_id,
					CAST(NULL AS varchar(max)) AS text_value,
					CAST(NULL AS float) AS float_value,
					CAST(NULL AS boolean) AS bit_value,
					CAST(NULL AS timestamp) AS date_value
			FROM vr_elementsToClear AS c
				LEFT JOIN vr_elements AS e
				ON e.element_id = c.value
				INNER JOIN fg_instance_elements AS i
				ON i.application_id = vr_application_id AND i.element_id = c.value
			WHERE e.element_id IS NULL
			
			UNION ALL
			
			SELECT e.element_id, e.ref_element_id, e.instance_id,
				e.text_value, e.float_value, e.bit_value, e.date_value
			FROM vr_elements AS e
		) AS x
		LEFT JOIN fg_instance_elements AS e -- First part checks element_id. We split them for performance reasons
		ON e.application_id = vr_application_id AND e.element_id = x.element_id
		LEFT JOIN fg_instance_elements AS e1 -- Second part checks InstanceID and RefElementID
		ON e1.application_id = vr_application_id AND
			x.ref_element_id IS NOT NULL AND x.instance_id IS NOT NULL AND 
			e1.ref_element_id = x.ref_element_id AND e1.instance_id = x.instance_id
	WHERE (COALESCE(e.element_id, e1.element_id) IS NULL AND 
			NOT (x.text_value IS NULL AND x.float_value IS NULL AND
				x.bit_value IS NULL AND x.date_value IS NULL
			)
		) OR 
		(x.text_value IS NULL AND COALESCE(e.text_value, e1.text_value) IS NOT NULL) OR
		(x.text_value IS NOT NULL AND COALESCE(e.text_value, e1.text_value) IS NULL) OR
		(x.text_value IS NOT NULL AND COALESCE(e.text_value, e1.text_value) IS NOT NULL AND 
			x.text_value <> COALESCE(e.text_value, e1.text_value)) OR
		(x.float_value IS NULL AND COALESCE(e.float_value, e1.float_value) IS NOT NULL) OR
		(x.float_value IS NOT NULL AND COALESCE(e.float_value, e1.float_value) IS NULL) OR
		(x.float_value IS NOT NULL AND COALESCE(e.float_value, e1.float_value) IS NOT NULL AND 
			x.float_value <> COALESCE(e.float_value, e1.float_value)) OR
		(x.bit_value IS NULL AND COALESCE(e.bit_value, e1.bit_value) IS NOT NULL) OR
		(x.bit_value IS NOT NULL AND COALESCE(e.bit_value, e1.bit_value) IS NULL) OR
		(x.bit_value IS NOT NULL AND COALESCE(e.bit_value, e1.bit_value) IS NOT NULL AND 
			x.bit_value <> COALESCE(e.bit_value, e1.bit_value)) OR
		(x.date_value IS NULL AND COALESCE(e.date_value, e1.date_value) IS NOT NULL) OR
		(x.date_value IS NOT NULL AND COALESCE(e.date_value, e1.date_value) IS NULL) OR
		(x.date_value IS NOT NULL AND COALESCE(e.date_value, e1.date_value) IS NOT NULL AND 
			x.date_value <> COALESCE(e.date_value, e1.date_value))
	-- end of Save Changes
	
	-- Update Existing Data
	-- A: Update based on element_id. We split them for performance reasons
	UPDATE IE
		SET TextValue = gfn_verify_string(ref.text_value),
			FloatValue = ref.float_value,
			BitValue = ref.bit_value,
			DateValue = ref.date_value,
			LastModifierUserID = vr_creator_user_id,
			LastModificationDate = vr_creation_date,
		 deleted = FALSE
	FROM vr_elements AS ref
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = ref.element_id
	
	-- B: Update based on RefElementID and InstanceID
	UPDATE IE
		SET TextValue = gfn_verify_string(ref.text_value),
			FloatValue = ref.float_value,
			BitValue = ref.bit_value,
			DateValue = ref.date_value,
			LastModifierUserID = vr_creator_user_id,
			LastModificationDate = vr_creation_date,
		 deleted = FALSE
	FROM vr_elements AS ref
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND
			ie.ref_element_id = ref.ref_element_id AND ie.instance_id = ref.instance_id
	-- end of Update Existing Data
	
	DECLARE vr_count INTEGER = @vr_rowcount
	
	-- Clear Empty Elements
	UPDATE IE
		SET TextValue = NULL,
			FloatValue = NULL,
			BitValue = NULL,
			DateValue = NULL,
			LastModifierUserID = vr_creator_user_id,
			LastModificationDate = vr_creation_date,
		 deleted = FALSE
	FROM vr_elementsToClear AS ref
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = ref.value
		
	SET vr_count = @vr_rowcount + vr_count
	
	DECLARE vr_file_owner_ids GuidTableType
	DECLARE vr__result INTEGER = 0
	
	INSERT INTO vr_file_owner_ids (Value)
	SELECT DISTINCT owner_ids.value
	FROM (
			SELECT c.value
			FROM vr_elementsToClear AS c
			
			UNION ALL 
			
			SELECT f.owner_id
			FROM vr_files AS f
		) AS owner_ids
		
	EXEC dct_p_remove_owners_files vr_application_id, vr_file_owner_ids, vr__result output
	-- end of Clear Empty Elements
	
	INSERT INTO fg_instance_elements(
		ApplicationID,
		ElementID,
		InstanceID,
		RefElementID,
		Title,
		SequenceNumber,
		type,
		Info,
		TextValue,
		FloatValue,
		BitValue,
		DateValue,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id,
		   ref.element_id,
		   ref.instance_id,
		   ref.ref_element_id,
		   efe.title,
		   COALESCE(efe.sequence_number, ref.sequence_nubmer),
		   efe.type,
		   efe.info,
		   gfn_verify_string(ref.text_value),
		   ref.float_value,
		   ref.bit_value,
		   ref.date_value,
		   vr_creator_user_id,
		   vr_creation_date,
		   0
	FROM vr_elements AS ref
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = ref.ref_element_id
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = ref.element_id
		LEFT JOIN fg_instance_elements AS ie1
		ON ie1.application_id = vr_application_id AND
			ie1.ref_element_id = ref.ref_element_id AND ie1.instance_id = ref.instance_id
	WHERE COALESCE(ie.element_id, ie1.element_id) IS NULL
	
	SET vr_count = @vr_rowcount + vr_count + 1
	
	EXEC dct_p_add_files vr_application_id, NULL, NULL, vr_files, vr_creator_user_id, vr_creation_date, vr__result output
	
	-- Set Selected Guids
	UPDATE S
		SET deleted = TRUE,
			LastModifierUserID = vr_creator_user_id,
			LastModificationDate = vr_creation_date
	FROM (
			SELECT DISTINCT a.element_id
			FROM vr_elements AS a
			
			UNION
			
			SELECT DISTINCT c.value
			FROM vr_elementsToClear AS c
		) AS e
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND s.element_id = e.element_id
	
	UPDATE S
		SET deleted = FALSE,
			LastModifierUserID = vr_creator_user_id,
			LastModificationDate = vr_creation_date
	FROM vr_guid_items AS g
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND 
			s.element_id = g.first_value AND s.selected_id = g.second_value
	
	INSERT INTO fg_selected_items (ApplicationID, ElementID, 
		SelectedID, LastModifierUserID, LastModificationDate, Deleted)
	SELECT vr_application_id, g.first_value, g.second_value, vr_creator_user_id, vr_creation_date, 0
	FROM vr_guid_items AS g
		INNER JOIN fg_instance_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = g.first_value
		LEFT JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND 
			s.element_id = g.first_value AND s.selected_id = g.second_value
	WHERE s.element_id IS NULL
	-- end of Set Selected Guids
	
	SELECT vr_count
END;


DROP PROCEDURE IF EXISTS fg_get_form_instances;

CREATE PROCEDURE fg_get_form_instances
	vr_application_id		UUID,
	vr_strInstanceIDs		varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strInstanceIDs, vr_delimiter) AS ref
	
	EXEC fg_p_get_form_instances_by_ids vr_application_id, vr_instanceIDs
END;


DROP PROCEDURE IF EXISTS fg_get_form_instance_elements;

CREATE PROCEDURE fg_get_form_instance_elements
	vr_application_id	UUID,
	vr_strInstanceIDs	varchar(max),
	vr_filled		 BOOLEAN,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	
	INSERT INTO vr_instanceIDs (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strInstanceIDs, vr_delimiter) AS ref
	
	DECLARE vr_element_ids GuidTableType
	INSERT INTO vr_element_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_e_l_count INTEGER = (SELECT COUNT(*) FROM vr_element_ids)
	
	SELECT	ie.element_id,
			ie.instance_id,
			ie.ref_element_id,
			COALESCE(efe.title, ie.title) AS title,
			efe.name,
			efe.help,
			efe.sequence_number,
			efe.type,
			COALESCE(efe.info, ie.info) AS info,
			efe.weight,
			ie.text_value,
			ie.float_value,
			ie.bit_value,
			ie.date_value,
			CAST(1 AS boolean) AS filled,
			COALESCE(efe.necessary, FALSE) AS necessary,
			efe.unique_value,
			CAST((
				SELECT COUNT(c.id)
				FROM fg_changes AS c
				WHERE c.application_id = vr_application_id AND c.element_id = ie.element_id AND deleted = FALSE
			) AS integer) AS editions_count,
			un.user_id AS creator_user_id,
			un.username AS creator_username,
			un.first_name AS creator_first_name,
			un.last_name AS creator_last_name
	FROM vr_instanceIDs AS ins
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.instance_id = ins.value
		LEFT JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = ie.ref_element_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ie.creator_user_id
	WHERE (vr_filled IS NULL OR vr_filled = 1) AND ie.deleted = FALSE AND
		(vr_e_l_count = 0 OR ie.element_id IN (SELECT ref.value FROM vr_element_ids AS ref))
	
	UNION ALL
	
	SELECT	efe.element_id,
			fi.instance_id,
			NULL AS ref_element_id,
			efe.title,
			efe.name,
			efe.help,
			efe.sequence_number,
			efe.type,
			efe.info,
			efe.weight,
			NULL AS text_value,
			NULL AS float_value,
			NULL AS bit_value,
			NULL AS date_value,
			CAST(0 AS boolean) AS filled,
			COALESCE(efe.necessary, FALSE) AS necessary,
			efe.unique_value,
			CAST(0 AS integer) AS editions_count,
			NULL AS creator_user_id,
			NULL AS creator_username,
			NULL AS creator_first_name,
			NULL AS creator_last_name
	FROM vr_instanceIDs AS ins
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = ins.value
		INNER JOIN f_g_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.form_id = fi.form_id
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND 
			ie.ref_element_id = efe.element_id AND ie.deleted = FALSE
	WHERE ie.element_id IS NULL AND (vr_filled IS NULL OR vr_filled = 0) AND efe.deleted = FALSE AND
		(vr_e_l_count = 0 OR efe.element_id IN (SELECT ref.value FROM vr_element_ids AS ref))
END;


DROP PROCEDURE IF EXISTS fg_get_selected_guids;

CREATE PROCEDURE fg_get_selected_guids
	vr_application_id	UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	INSERT INTO vr_element_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref

	SELECT	s.element_id,
			s.selected_id AS id,
			CASE
				WHEN nd.node_id IS NOT NULL THEN nd.name
				ELSE LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))
			END AS name
	FROM vr_element_ids AS i_ds
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND s.element_id = i_ds.value AND s.deleted = FALSE
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = s.selected_id AND nd.deleted = FALSE
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = s.selected_id
	WHERE nd.node_id IS NOT NULL OR un.user_id IS NOT NULL
END;


DROP PROCEDURE IF EXISTS fg_get_element_changes;

CREATE PROCEDURE fg_get_element_changes
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 10000)) *
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY c.id DESC) AS row_number,
					c.id,
					c.element_id,
					efe.info,
					c.text_value,
					c.bit_value,
					c.float_value,
					c.date_value,
					c.creation_date,
					c.creator_user_id,
					un.username AS creator_username,
					un.first_name AS creator_first_name,
					un.last_name AS creator_last_name
			FROM fg_changes AS c
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = c.creator_user_id
				INNER JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.element_id = c.element_id
				INNER JOIN fg_extended_form_elements AS efe
				ON efe.application_id = vr_application_id AND efe.element_id = e.ref_element_id
			WHERE c.application_id = vr_application_id AND c.element_id = vr_element_id AND c.deleted = FALSE
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
END;


DROP PROCEDURE IF EXISTS fg_p_set_form_instance_as_filled;

CREATE PROCEDURE fg_p_set_form_instance_as_filled
	vr_application_id		UUID,
	vr_instanceID			UUID,
	vr_filling_date	 TIMESTAMP,
	vr_last_modifier_user_id	UUID,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_form_instances
		SET Filled = 1,
			FillingDate = vr_filling_date,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_filling_date
	WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID AND Filled = 0
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_instance_as_filled;

CREATE PROCEDURE fg_set_form_instance_as_filled
	vr_application_id		UUID,
	vr_instanceID			UUID,
	vr_filling_date	 TIMESTAMP,
	vr_last_modifier_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC fg_p_set_form_instance_as_filled vr_application_id, vr_instanceID, 
		vr_filling_date, vr_last_modifier_user_id, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_p_set_form_instance_as_not_filled;

CREATE PROCEDURE fg_p_set_form_instance_as_not_filled
	vr_application_id		UUID,
	vr_instanceID			UUID,
	vr_last_modifier_user_id	UUID,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_form_instances
		SET Filled = 0,
			LastModifierUserID = vr_last_modifier_user_id
	WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID AND Filled = 1 
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_instance_as_not_filled;

CREATE PROCEDURE fg_set_form_instance_as_not_filled
	vr_application_id		UUID,
	vr_instanceID			UUID,
	vr_last_modifier_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC fg_p_set_form_instance_as_not_filled vr_application_id, 
		vr_instanceID, vr_last_modifier_user_id, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_is_director;

CREATE PROCEDURE fg_is_director
	vr_application_id	UUID,
	vr_instanceID		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM fg_form_instances 
		WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID
	) BEGIN
		SET vr_instanceID = (
			SELECT TOP(1) InstanceID 
			FROM fg_instance_elements 
			WHERE ApplicationID = vr_application_id AND ElementID = vr_instanceID
		)
	END
	
	DECLARE vr_director_id UUID, vr_isAdmin BOOLEAN
	
	SELECT vr_director_id = DirectorID, vr_isAdmin = admin
	FROM fg_form_instances
	WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID
	
	IF vr_isAdmin = 0 SET vr_isAdmin = NULL
	
	IF vr_director_id IS NOT NULL AND vr_director_id = vr_user_id BEGIN
		SELECT CAST(1 AS boolean)
		RETURN
	END
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids
	EXEC cn_p_get_member_node_ids vr_application_id, vr_user_id, NULL, N'Accepted', vr_isAdmin
	
	IF vr_director_id IS NOT NULL AND vr_director_id IN(SELECT * FROM vr_node_ids)
		SELECT CAST(1 AS boolean)
	ELSE
		SELECT CAST(0 AS boolean)
END;


DROP PROCEDURE IF EXISTS fg_p_set_form_owner;

CREATE PROCEDURE fg_p_set_form_owner
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_form_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM fg_form_owners
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id
	) BEGIN
		UPDATE fg_form_owners
			SET FormID = vr_form_id,
			 deleted = FALSE,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id
	END
	ELSE BEGIN
		INSERT INTO fg_form_owners(
			ApplicationID,
			OwnerID,
			FormID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_owner_id,
			vr_form_id,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_form_owner;

CREATE PROCEDURE fg_set_form_owner
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_form_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC fg_p_set_form_owner vr_application_id, vr_owner_id, 
		vr_form_id, vr_creator_user_id, vr_creation_date, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_arithmetic_delete_form_owner;

CREATE PROCEDURE fg_arithmetic_delete_form_owner
	vr_application_id			UUID,
	vr_owner_id				UUID,
	vr_form_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_form_owners
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND FormID = vr_form_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_get_owner_form;

CREATE PROCEDURE fg_get_owner_form
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_form_ids GuidTableType
	
	INSERT INTO vr_form_ids
	SELECT FormID
	FROM fg_form_owners
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	
	EXEC fg_p_get_forms_by_ids vr_application_id, vr_form_ids
END;


DROP PROCEDURE IF EXISTS fg_initialize_owner_form_instance;

CREATE PROCEDURE fg_initialize_owner_form_instance
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_form_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_form_id IS NULL BEGIN
		SET vr_form_id = (
			SELECT TOP(1) FormID 
			FROM fg_form_owners
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
		)
	END
	
	IF vr_form_id IS NULL BEGIN
		SELECT vr_form_id = FormID 
		FROM fg_form_owners AS fo
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_type_id = fo.owner_id
		WHERE fo.application_id = vr_application_id AND nd.node_id = vr_owner_id AND fo.deleted = FALSE
	END
	
	IF vr_form_id IS NULL OR vr_owner_id IS NULL SELECT NULL
	ELSE BEGIN
		DECLARE vr_instanceID UUID = (
			SELECT TOP(1) InstanceID
			FROM fg_form_instances
			WHERE ApplicationID = vr_application_id AND 
				FormID = vr_form_id AND OwnerID = vr_owner_id AND deleted = FALSE
		)
			
		IF vr_instanceID IS NOT NULL SELECT vr_instanceID
		ELSE BEGIN
			SET vr_instanceID = gen_random_uuid()
			
			DECLARE vr__result INTEGER
			
			DECLARE vr_instances FormInstanceTableType
			
			INSERT INTO vr_instances (InstanceID, FormID, OwnerID, DirectorID, admin)
			VALUES (vr_instanceID, vr_form_id, vr_owner_id, NULL, NULL)
			
			EXEC fg_p_create_form_instance vr_application_id, vr_instances, vr_creator_user_id, vr_creation_date, vr__result output
				
			IF vr__result > 0 SELECT vr_instanceID
		END
	END
END;


DROP PROCEDURE IF EXISTS fg_set_element_limits;

CREATE PROCEDURE fg_set_element_limits
	vr_application_id		UUID,
	vr_owner_id			UUID,
	vr_strElementIDs		varchar(max),
	vr_delimiter			char,
    vr_creator_user_id		UUID,
    vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_existingIDs GuidTableType, vr_not_existingIDs GuidTableType
	DECLARE vr_count INTEGER
	
	INSERT INTO vr_existingIDs
	SELECT ref.value
	FROM vr_element_ids AS ref
		INNER JOIN fg_element_limits AS el
		ON el.element_id = ref.value
	WHERE el.application_id = vr_application_id AND el.owner_id = vr_owner_id
	
	SET vr_count = (SELECT COUNT(*) FROM vr_existingIDs)
	
	UPDATE fg_element_limits
		SET LastModifierUserID = vr_creator_user_id,
			LastModificationDate = vr_creation_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id
	
	IF vr_count > 0 BEGIN
		UPDATE EL
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		FROM vr_existingIDs AS e
			INNER JOIN fg_element_limits AS el
			ON el.element_id = e.value
		WHERE el.application_id = vr_application_id AND el.owner_id = vr_owner_id
		
		IF @vr_rowcount <= 0 BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	INSERT INTO vr_not_existingIDs
	SELECT e.value
	FROM vr_element_ids AS e
	WHERE e.value NOT IN(SELECT ref.value FROM vr_existingIDs AS ref)
	
	SET vr_count = (SELECT COUNT(*) FROM vr_not_existingIDs)
	
	IF vr_count > 0 BEGIN
		INSERT INTO fg_element_limits(
			ApplicationID,
			OwnerID,
			ElementID,
			Necessary,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT vr_application_id, vr_owner_id, ne.value, 
			COALESCE(efe.necessary, FALSE), vr_creator_user_id, vr_creation_date, 0
		FROM vr_not_existingIDs AS ne
			INNER JOIN fg_extended_form_elements AS efe
			ON efe.application_id = vr_application_id AND efe.element_id = ne.value
	
		IF @vr_rowcount <= 0 BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS fg_get_element_limits;

CREATE PROCEDURE fg_get_element_limits
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_id UUID = (
		SELECT TOP(1) FormID 
		FROM fg_form_owners
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	)
		
	IF vr_form_id IS NULL BEGIN
		SELECT vr_form_id = FormID, vr_owner_id = nd.node_type_id
		FROM fg_form_owners AS fo
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_type_id = fo.owner_id
		WHERE fo.application_id = vr_application_id AND nd.node_id = vr_owner_id AND fo.deleted = FALSE
	END
	
	IF vr_form_id IS NOT NULL BEGIN
		SELECT el.element_id,
			   efe.title,
			   el.necessary,
			   efe.type,
			   efe.info
		FROM fg_element_limits AS el
			INNER JOIN fg_extended_form_elements AS efe
			ON efe.application_id = vr_application_id AND 
				efe.element_id = el.element_id AND efe.deleted = FALSE
		WHERE el.application_id = vr_application_id AND 
			el.owner_id = vr_owner_id AND efe.form_id = vr_form_id AND el.deleted = FALSE
		ORDER BY efe.sequence_number
	END
END;


DROP PROCEDURE IF EXISTS fg_set_element_limit_necessity;

CREATE PROCEDURE fg_set_element_limit_necessity
	vr_application_id			UUID,
	vr_owner_id				UUID,
	vr_element_id				UUID,
	vr_necessary			 BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_element_limits
		SET Necessary = COALESCE(vr_necessary, CAST(0 AS boolean)),
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND ElementID = vr_element_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_arithmetic_delete_element_limit;

CREATE PROCEDURE fg_arithmetic_delete_element_limit
	vr_application_id			UUID,
	vr_owner_id				UUID,
	vr_element_id				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_element_limits
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND ElementID = vr_element_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_get_common_form_instance_ids;

CREATE PROCEDURE fg_get_common_form_instance_ids
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_filledOwnerID	UUID,
	vr_has_limit	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT fi.instance_id AS id
	FROM fg_form_instances AS fi
		INNER JOIN (
			SELECT ref.form_id
			FROM (
					SELECT fo.form_id, COUNT(el.element_id) AS cnt
					FROM fg_form_owners AS fo
						LEFT JOIN fg_element_limits AS el
						INNER JOIN fg_extended_form_elements AS efe
						ON efe.application_id = vr_application_id AND efe.element_id = el.element_id
						ON el.application_id = vr_application_id AND 
							el.owner_id = fo.owner_id AND efe.form_id = fo.form_id AND el.deleted = FALSE
					WHERE fo.application_id = vr_application_id AND 
						fo.owner_id = vr_owner_id AND fo.deleted = FALSE
					GROUP BY fo.form_id
				) AS ref
			WHERE vr_has_limit IS NULL OR vr_has_limit = 0 OR ref.cnt > 0
		) AS fid
		ON fi.form_id = fid.form_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_filledOwnerID
END;


DROP PROCEDURE IF EXISTS fg_p_get_form_records;

CREATE PROCEDURE fg_p_get_form_records
	vr_application_id		UUID,
	vr_form_id				UUID,
	vr_element_idsTemp		GuidTableType readonly,
	vr_instanceIDsTemp	GuidTableType readonly,
	vr_owner_idsTemp		GuidTableType readonly,
	vr_filters_temp		FormFilterTableType readonly,
	vr_lower_boundary	 INTEGER,
	vr_count			 INTEGER,
	vr_sortByElementID	UUID,
	vr_desc			 BOOLEAN
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	INSERT INTO vr_element_ids SELECT * FROM vr_element_idsTemp
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs SELECT * FROM vr_instanceIDsTemp
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids SELECT * FROM vr_owner_idsTemp
	
	DECLARE vr_filters FormFilterTableType
	INSERT INTO vr_filters SELECT * FROM vr_filters_temp
	
	-- Preparing
	
	CREATE TABLE #Owners (Value UUID primary key clustered)
	
	INSERT INTO #Owners (Value) SELECT o.value FROM vr_owner_ids AS o
	
	DECLARE vr_has_owner BOOLEAN = CASE WHEN (SELECT TOP(1) * FROM vr_owner_ids) IS NOT NULL THEN 1 ELSE 0 END

	
	DECLARE vr__elem_ids KeyLessGuidTableType
	
	INSERT INTO vr__elem_ids (Value)
	SELECT efe.element_id
	FROM vr_element_ids AS e
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = e.value
	WHERE efe.form_id = vr_form_id
	ORDER BY efe.sequence_number
	
	IF (SELECT TOP(1) * FROM vr_element_ids) IS NULL BEGIN
		INSERT INTO vr__elem_ids (Value)
		SELECT ElementID 
		FROM fg_extended_form_elements
		WHERE ApplicationID = vr_application_id AND FormID = vr_form_id AND deleted = FALSE
		ORDER BY SequenceNumber ASC
	END
	
	IF vr_sortByElementID IS NULL SET vr_sortByElementID = (SELECT TOP(1) Value FROM vr__elem_ids)
	
	IF vr_count IS NULL SET vr_count = 10000
	IF COALESCE(vr_lower_boundary, 0) < 1 SET vr_lower_boundary = 1
	DECLARE vr_upper_boundary INTEGER = vr_lower_boundary + vr_count - 1
	
	CREATE TABLE #InstanceIDs (InstanceID UUID primary key clustered,
		OwnerID UUID, RowNum bigint)
		
	DECLARE vr_instancesCount bigint = 0
	
	DECLARE vr__stR_SBEID varchar(100), vr__stR_FORMID varchar(100),
		vr__stR_LB varchar(100), vr__stR_UB varchar(100)
	SELECT vr__stR_SBEID = CAST(vr_sortByElementID AS varchar(100)),
		vr__stR_FORMID = CAST(vr_form_id AS varchar(100))
	
	IF EXISTS(SELECT TOP(1) * FROM vr_instanceIDs) BEGIN
		INSERT INTO #InstanceIDs (InstanceID, OwnerID, RowNum)
		SELECT	i.value, 
				fi.owner_id, 
				ROW_NUMBER() OVER(ORDER BY i.value ASC) AS row_num
		FROM vr_instanceIDs AS i
			LEFT JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.instance_id = i.value
	
		SET vr_instancesCount = (SELECT COUNT(*) FROM #InstanceIDs)
	END
	ELSE BEGIN	
		DECLARE vr__proc varchar(max)
		
		SET vr__proc = 'INSERT INTO #InstanceIDs SELECT InstanceID, OwnerID, RowNum FROM ' + 
			'(SELECT ROW_NUMBER() OVER(ORDER BY r.row_num) AS row_num, r.instance_id, r.owner_id ' +
			'FROM (' +
			'SELECT ROW_NUMBER() OVER(PARTITION BY fi.instance_id ORDER BY fi.instance_id) AS p, ' + 
			'ROW_NUMBER() OVER(ORDER BY ' +
			(CASE WHEN vr_sortByElementID IS NULL THEN 'fi.instance_id ' ELSE 'ie.element_id ' END) +
			(CASE WHEN vr_desc = 1 THEN 'DESC ' ELSE '' END) +
			') RowNum, fi.instance_id, fi.owner_id FROM ' +
			(CASE WHEN vr_has_owner = 1 THEN '#Owners AS ow INNER JOIN ' ELSE '' END) +
			'fg_form_instances AS fi ' +
			(CASE WHEN vr_has_owner = 1 THEN 'ON fi.application_id = ''' + 
				CAST(vr_application_id AS varchar(50)) + ''' AND fi.owner_id = ow.value ' ELSE '' END) +
			(
				CASE 
					WHEN vr_sortByElementID IS NOT NULL
						THEN 'LEFT JOIN fg_instance_elements AS ie ' +
							'ON ie.application_id = ''' + CAST(vr_application_id AS varchar(50)) + 
								''' AND ie.instance_id = fi.instance_id AND ' +
							'ie.ref_element_id = N''' + vr__stR_SBEID + ''' AND ie.deleted = FALSE '
					ELSE '' 
				END
			) +
			'WHERE fi.form_id = N''' + vr__stR_FORMID + ''' AND fi.deleted = FALSE ' +
			')  AS r WHERE r.p = 1 ' +
			') AS ref'
		
		EXEC (vr__proc)
		
		SET vr_instancesCount = @vr_rowcount
	END
	
	IF vr_instancesCount > 0 AND EXISTS(SELECT TOP(1) * FROM vr_filters) BEGIN
		DECLARE vr_cur_instance_ids GuidTableType
		
		INSERT INTO vr_cur_instance_ids (Value)
		SELECT i.instance_id
		FROM #InstanceIDs AS i
	
		DELETE I
		FROM #InstanceIDs AS i
			LEFT JOIN fg_fn_filter_instances(
				vr_application_id, NULL, vr_cur_instance_ids, vr_filters, ',', 1
			) AS ret
			ON ret.instance_id = i.instance_id
		WHERE ret.instance_id IS NULL
	END
	
	UPDATE I
		SET RowNum = CASE WHEN x.instance_id IS NULL THEN 0 ELSE x.row_num END
	FROM #InstanceIDs AS i
		LEFT JOIN (
			SELECT	d.instance_id,
					d.owner_id,
					ROW_NUMBER() OVER (ORDER BY d.row_num ASC) AS row_num
			FROM (
					SELECT	i.instance_id,
							i.owner_id,
							ROW_NUMBER() OVER (ORDER BY i.row_num ASC) AS row_num
					FROM #InstanceIDs AS i
				) AS d
			WHERE d.row_num BETWEEN vr_lower_boundary AND vr_upper_boundary
		) AS x
		ON x.instance_id = i.instance_id
	
	DELETE #InstanceIDs
	WHERE RowNum = 0
	
	SET vr_instancesCount = (SELECT COUNT(*) FROM #InstanceIDs)
	
	-- End of Preparing
	
	
	CREATE TABLE #Result
	(
		InstanceID		UUID,
		OwnerID			UUID,
		RefElementID	UUID,
		CreationDate TIMESTAMP,
		BodyText	 VARCHAR(max),
		RowNum			bigint
	)

	INSERT INTO #Result(InstanceID, OwnerID, RefElementID, CreationDate, BodyText, RowNum)
	SELECT	fi.instance_id, 
			instids.owner_id,
			elids.value, 
			fi.creation_date,
			fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr__elem_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id
		

	DECLARE vr_lst varchar(max)
	SELECT vr_lst = COALESCE(vr_lst + ', ', '') + '[' + CAST(q.value AS varchar(max)) + ']'
	FROM (SELECT ref.value FROM vr__elem_ids AS ref) AS q
	
	SET vr__proc = 'SELECT * FROM ('
	
	DECLARE vr_batchSize bigint = 1000
	DECLARE vr_lower bigint = 0
	
	WHILE vr_instancesCount >= 0 BEGIN
		IF vr_lower > 0 SET vr__proc = vr__proc + ' UNION ALL '
		
		SET vr__proc = vr__proc + 'SELECT InstanceID, OwnerID, CreationDate, '+ vr_lst +  
			'FROM (SELECT InstanceID, OwnerID, RefElementID, CreationDate, BodyText
			FROM #Result ' + 
			'WHERE RowNum > ' + CAST(vr_lower AS varchar(20)) + ' AND ' + 
				'RowNum <= ' + CAST(vr_lower + vr_batchSize AS varchar(20)) + ') P
			PIVOT (MAX(BodyText) FOR RefElementID IN('+ vr_lst + ' )) AS pvt '
			
		SET vr_instancesCount = vr_instancesCount - vr_batchSize
		SET vr_lower = vr_lower + vr_batchSize
	END
	
	SET vr__proc = vr__proc + ') AS table_name'
	IF vr_sortByElementID IS NOT NULL AND vr__stR_SBEID IS NOT NULL BEGIN
		SET vr__proc = vr__proc + ' ORDER BY [' + vr__stR_SBEID + ']'
		IF vr_desc = 1 SET vr__proc = vr__proc + ' DESC'
	END
	
	EXEC(vr__proc)
END;


DROP PROCEDURE IF EXISTS fg_get_form_records;

CREATE PROCEDURE fg_get_form_records
	vr_application_id		UUID,
	vr_form_id				UUID,
	vr_element_idsTemp		GuidTableType readonly,
	vr_instanceIDsTemp	GuidTableType readonly,
	vr_owner_idsTemp		GuidTableType readonly,
	vr_filters_temp		FormFilterTableType readonly,
	vr_lower_boundary	 INTEGER,
	vr_count			 INTEGER,
	vr_sortByElementID	UUID,
	vr_desc			 BOOLEAN
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	INSERT INTO vr_element_ids SELECT * FROM vr_element_idsTemp
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs SELECT * FROM vr_instanceIDsTemp
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids SELECT * FROM vr_owner_idsTemp
	
	DECLARE vr_filters FormFilterTableType
	INSERT INTO vr_filters SELECT * FROM vr_filters_temp
	
	EXEC fg_p_get_form_records vr_application_id, vr_form_id, vr_element_ids, vr_instanceIDs, 
		vr_owner_ids, vr_filters, vr_lower_boundary, vr_count, vr_sortByElementID, vr_desc
END;


DROP PROCEDURE IF EXISTS fg_get_form_statistics;

CREATE PROCEDURE fg_get_form_statistics
	vr_application_id	UUID,
	vr_owner_id UUID,
	vr_instanceID UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	SUM(x.weight) AS weight_sum,
			SUM(x.avg) AS sum,
			SUM(x.weighted_avg) AS weighted_sum,
			AVG(x.avg) AS avg,
			CASE 
				WHEN SUM(x.weight) = 0 THEN AVG(x.avg) 
				ELSE SUM(x.weighted_avg) / SUM(x.weight) 
			END AS weighted_avg,
			MIN(x.avg) AS min,
			MAX(x.avg) AS max,
			VAR(x.avg) AS var,
			STDEV(x.avg) AS st_dev
	FROM (
			SELECT	efe.element_id,
					COALESCE(MAX(efe.weight), 0) AS weight,
					MIN(ie.float_value) AS min,
					MAX(ie.float_value) AS max,
					AVG(ie.float_value) AS avg,
					(AVG(ie.float_value) * COALESCE(MAX(efe.weight), 0)) AS weighted_avg,
					COALESCE(VAR(ie.float_value), 0) AS var,
					COALESCE(STDEV(ie.float_value), 0) AS st_dev
			FROM fg_form_instances AS fi
				INNER JOIN fg_instance_elements AS ie
				ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND 
					ie.float_value IS NOT NULL AND ie.deleted = FALSE
				INNER JOIN fg_extended_form_elements AS efe
				ON efe.application_id = vr_application_id AND 
					efe.element_id = ie.ref_element_id AND efe.deleted = FALSE
			WHERE fi.application_id = vr_application_id AND fi.deleted = FALSE AND
				(vr_owner_id IS NOT NULL OR vr_instanceID IS NOT NULL) AND
				(vr_owner_id IS NULL OR fi.owner_id = vr_owner_id) AND
				(vr_instanceID IS NULL OR fi.instance_id = vr_instanceID)
			GROUP BY efe.element_id
		) AS x
END;


DROP PROCEDURE IF EXISTS fg_convert_form_to_table;

CREATE PROCEDURE fg_convert_form_to_table
	vr_application_id	UUID,
	vr_form_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_table_name varchar(200)
	DECLARE vr_element_ids TABLE (Seq INTEGER IDENTITY(1, 1) primary key clustered, Value UUID, Name varchar(200) )

	SELECT TOP(1) vr_table_name = 'FG_FRM_' + f.name
	FROM fg_extended_forms AS f
	WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id AND 
		COALESCE(f.name, N'') <> N'' AND f.deleted = FALSE
	
	IF COALESCE(vr_table_name, N'') = N'' BEGIN
		SELECT -1
		RETURN
	END

	INSERT INTO vr_element_ids(Value, Name)
	SELECT efe.element_id, N'Col_' + efe.name
	FROM fg_extended_form_elements AS efe
	WHERE efe.application_id = vr_application_id AND efe.form_id = vr_form_id AND 
		COALESCE(efe.name, N'') <> N'' AND efe.deleted = FALSE
	ORDER BY efe.sequence_number
	
	IF (SELECT COUNT(*) FROM vr_element_ids) = 0 BEGIN
		SELECT -1
		RETURN
	END

	CREATE TABLE #InstanceIDs (
		InstanceID UUID primary key clustered, 
		OwnerID UUID,
		CreatorID UUID,
		CreationDate TIMESTAMP,
		RowNum bigint
	)
		
	DECLARE vr_instancesCount bigint = 0

	DECLARE vr__proc varchar(max)
		
	INSERT INTO #InstanceIDs (RowNum, InstanceID, OwnerID, CreatorID, CreationDate)
	SELECT	ROW_NUMBER() OVER(ORDER BY fi.creation_date ASC, fi.instance_id ASC) RowNum, 
			fi.instance_id,
			fi.owner_id,
			fi.creator_user_id,
			fi.creation_date
	FROM fg_form_instances AS fi 
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = fi.owner_id
	WHERE fi.application_id = vr_application_id AND fi.form_id = vr_form_id AND fi.deleted = FALSE AND 
		(nd.node_id IS NULL OR COALESCE(nd.deleted, FALSE) = 0)

	UPDATE I
		SET RowNum = CASE WHEN x.instance_id IS NULL THEN 0 ELSE x.row_num END
	FROM #InstanceIDs AS i
		LEFT JOIN (
			SELECT	d.instance_id,
					ROW_NUMBER() OVER (ORDER BY d.row_num ASC) AS row_num
			FROM (
					SELECT	i.instance_id,
							ROW_NUMBER() OVER (ORDER BY i.row_num ASC) AS row_num
					FROM #InstanceIDs AS i
				) AS d
		) AS x
		ON x.instance_id = i.instance_id

	DELETE #InstanceIDs
	WHERE RowNum = 0

	SET vr_instancesCount = (SELECT COUNT(*) FROM #InstanceIDs)

	-- End of Preparing


	CREATE TABLE #Result (InstanceID UUID, Name varchar(200), Value VARCHAR(max), RowNum bigint)

	INSERT INTO #Result(InstanceID, Name, Value, RowNum)
	SELECT	fi.instance_id, 
			elids.name, 
			fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr_element_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id

	INSERT INTO #Result(InstanceID, Name, Value, RowNum)
	SELECT	fi.instance_id, 
			elids.name + '_id', 
			CAST(ie.element_id AS varchar(max)),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr_element_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id

	INSERT INTO #Result(InstanceID, Name, Value, RowNum)
	SELECT	fi.instance_id, 
			elids.name + '_text', 
			CAST(ie.text_value AS varchar(max)),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr_element_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id

	INSERT INTO #Result(InstanceID, Name, Value, RowNum)	
	SELECT	fi.instance_id, 
			elids.name + '_float', 
			CAST(ie.float_value AS varchar(max)),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr_element_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id
			
	INSERT INTO #Result(InstanceID, Name, Value, RowNum)
	SELECT	fi.instance_id, 
			elids.name + '_bit', 
			CAST(ie.bit_value AS varchar(max)),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr_element_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id
		
	INSERT INTO #Result(InstanceID, Name, Value, RowNum)
	SELECT	fi.instance_id, 
			elids.name + '_date', 
			CAST(ie.date_value AS varchar(max)),
			instids.row_num
	FROM #InstanceIDs AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN vr_element_ids AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id

	DECLARE vr_lst varchar(max), vr_select_lst varchar(max)

	SELECT vr_lst = COALESCE(vr_lst + ', ', '') + '[' + q.name + ']' + ',[' + q.name + '_id]' + + ',[' + q.name + '_text]' +
		',[' + q.name + '_float]' + ',[' + q.name + '_bit]' + ',[' + q.name + '_date]'
	FROM (SELECT ref.name FROM vr_element_ids AS ref) AS q

	SELECT vr_select_lst = COALESCE(vr_select_lst + ', ', '') + 
		'pvt.' + q.name + ']' + 
		',cast(pvt.' + q.name + '_id] AS uuid) AS ' + q.name + '_id]' + 
		',pvt.' + q.name + '_text]' +
		',cast(pvt.' + q.name + '_float] AS float) AS ' + q.name + '_float]' + 
		',cast(pvt.' + q.name + '_bit] AS boolean) AS ' + q.name + '_bit]' + 
		',cast(pvt.' + q.name + '_date] AS timestamp) AS ' + q.name + '_date]'
	FROM (SELECT ref.name FROM vr_element_ids AS ref) AS q

	IF (EXISTS (SELECT * FROM information_schema.tables 
		WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = vr_table_name))
	BEGIN
		EXEC ('DROP TABLE dbo.' + vr_table_name)
	END

	SET vr__proc = 'SELECT * into dbo.' + vr_table_name + ' FROM ('

	DECLARE vr_batchSize bigint = 1000
	DECLARE vr_lower bigint = 0

	WHILE vr_instancesCount >= 0 BEGIN
		IF vr_lower > 0 SET vr__proc = vr__proc + ' UNION ALL '
		
		SET vr__proc = vr__proc + 
			'SELECT pvt.instance_id, i.owner_id, i.creation_date, un.user_id, un.username, un.first_name, un.last_name, '+ vr_select_lst +  
			'FROM (SELECT InstanceID, Name, Value
			FROM #Result ' + 
			'WHERE RowNum > ' + CAST(vr_lower AS varchar(20)) + ' AND ' + 
				'RowNum <= ' + CAST(vr_lower + vr_batchSize AS varchar(20)) + ') P
			PIVOT (MAX(Value) FOR Name IN('+ vr_lst + ' )) AS pvt ' +
			'INNER JOIN #InstanceIDs AS i ' +
			'ON i.instance_id = pvt.instance_id ' +
			'LEFT JOIN usr_view_users AS un ' +
			'ON un.user_id = i.creator_id'
			
		SET vr_instancesCount = vr_instancesCount - vr_batchSize
		SET vr_lower = vr_lower + vr_batchSize
	END

	SET vr__proc = vr__proc + ') AS table_name'


	EXEC (vr__proc)
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS fg_get_template_status;

CREATE PROCEDURE fg_get_template_status
	vr_application_id		UUID,
	vr_ref_application_id	UUID,
	vr_strTemplateIDs		varchar(max),
	vr_delimiter			char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_template_ids GuidTableType

	INSERT INTO vr_template_ids (value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strTemplateIDs, vr_delimiter) AS ref
	
	SELECT	CAST(MAX(CAST(rnt.node_type_id AS varchar(50))) AS uuid) AS template_id,
			MAX(rnt.name) AS template_name,
			CAST(MAX(CAST(nt.node_type_id AS varchar(50))) AS uuid) AS activated_id,
			MAX(nt.name) AS activated_name,
			MAX(nt.creation_date) AS activation_date,
			CAST(MAX(CAST(usr.user_id AS varchar(50))) AS uuid) AS activator_user_id,
			MAX(usr.username) AS activator_username,
			MAX(usr.first_name) AS activator_first_name,
			MAX(usr.last_name) AS activator_last_name,
			COUNT(DISTINCT CASE WHEN elems.ref_deleted = 0 THEN elems.ref_element_id ELSE NULL END) AS template_elements_count,
			COUNT(DISTINCT CASE WHEN elems.deleted = FALSE THEN elems.element_id ELSE NULL END) AS elements_count,
			COUNT(DISTINCT
				CASE
					WHEN elems.ref_element_id IS NOT NULL AND elems.ref_deleted = 0 AND elems.element_id IS NULL THEN elems.ref_element_id
					ELSE NULL
				END
			) AS new_template_elements_count,
			COUNT(DISTINCT
				CASE
					WHEN elems.ref_element_id IS NOT NULL AND elems.element_id IS NOT NULL AND 
						elems.ref_deleted = 1 AND elems.deleted = FALSE THEN elems.ref_element_id
					ELSE NULL
				END
			) AS removed_template_elements_count,
			COUNT(DISTINCT
				CASE
					WHEN elems.ref_element_id IS NULL AND elems.element_id IS NOT NULL AND elems.deleted = FALSE THEN elems.element_id
					ELSE NULL
				END
			) AS new_custom_elements_count
	FROM vr_template_ids AS t 
		INNER JOIN fg_extended_forms AS rf
		ON rf.application_id = vr_ref_application_id AND rf.form_id = t.value
		INNER JOIN fg_extended_forms AS f
		ON f.application_id = vr_application_id AND f.template_form_id = rf.form_id
		INNER JOIN fg_form_owners AS ro
		ON ro.application_id = vr_ref_application_id AND ro.form_id = rf.form_id AND ro.deleted = FALSE
		INNER JOIN cn_node_types AS rnt
		ON rnt.application_id = vr_ref_application_id AND rnt.node_type_id = ro.owner_id AND rnt.deleted = FALSE
		INNER JOIN fg_form_owners AS o
		ON o.application_id = vr_application_id AND o.form_id = f.form_id AND o.deleted = FALSE
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = o.owner_id AND nt.deleted = FALSE
		INNER JOIN usr_view_users AS usr
		ON usr.user_id = nt.creator_user_id
		INNER JOIN (
			SELECT	re.application_id AS ref_app_id, 
					re.form_id AS ref_form_id,
					re.element_id AS ref_element_id,
					COALESCE(re.deleted, FALSE) AS ref_deleted,
					e.application_id AS app_id,
					e.form_id AS form_id,
					e.element_id AS element_id,
					COALESCE(e.deleted, FALSE) AS deleted
			FROM fg_extended_form_elements AS re
				FULL OUTER JOIN fg_extended_form_elements AS e
				ON e.template_element_id = re.element_id
			WHERE (re.application_id IS NULL OR re.application_id = vr_ref_application_id) AND
				(e.application_id IS NULL OR e.application_id = vr_application_id)
		) AS elems
		ON (elems.ref_form_id = rf.form_id AND (elems.form_id IS NULL OR elems.form_id = f.form_id)) OR 
			(elems.form_id = f.form_id AND (elems.ref_form_id IS NULL OR elems.ref_form_id = Rf.form_id))
	GROUP BY rf.form_id, f.form_id
END;


-- Polls

DROP PROCEDURE IF EXISTS fg_p_get_polls_by_ids;

CREATE PROCEDURE fg_p_get_polls_by_ids
	vr_application_id	UUID,
	vr_poll_ids_temp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_poll_ids KeyLessGuidTableType
	INSERT INTO vr_poll_ids (Value) SELECT Value FROM vr_poll_ids_temp
	
	SELECT	p.poll_id, 
			p.is_copy_of_poll_id,
			p.owner_id,
			p.name, 
			p2.name AS ref_name,
			p.description, 
			p2.description AS ref_description, 
			p.begin_date, 
			p.finish_date,
			CASE
				WHEN p.owner_id IS NULL THEN p.show_summary
				ELSE COALESCE(p2.show_summary, p.show_summary)
			END AS show_summary,
			CASE
				WHEN p.owner_id IS NULL THEN p.hide_contributors
				ELSE COALESCE(p2.hide_contributors, p.hide_contributors)
			END AS hide_contributors
	FROM vr_poll_ids AS i_ds
		INNER JOIN fg_polls AS p
		ON p.application_id = vr_application_id AND p.poll_id = i_ds.value
		LEFT JOIN fg_polls AS p2
		ON p2.application_id = vr_application_id AND p2.poll_id = p.is_copy_of_poll_id
	ORDER BY i_ds.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS fg_get_polls_by_ids;

CREATE PROCEDURE fg_get_polls_by_ids
	vr_application_id	UUID,
	vr_strPollIDs		varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_poll_ids KeyLessGuidTableType
	
	INSERT INTO vr_poll_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strPollIDs, vr_delimiter) AS ref
	
	EXEC fg_p_get_polls_by_ids vr_application_id, vr_poll_ids
END;


DROP PROCEDURE IF EXISTS fg_get_polls;

CREATE PROCEDURE fg_get_polls
	vr_application_id	UUID,
	vr_isCopyOfPollID	UUID,
	vr_owner_id		UUID,
	vr_archive	 BOOLEAN,
	vr_searchText	 VARCHAR(500),
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_temp_ids KeyLessGuidTableType
	
	SET vr_archive = COALESCE(vr_archive, 0)
	SET vr_count = COALESCE(vr_count, 20)
	
	IF COALESCE(vr_searchText, N'') = N'' BEGIN
		INSERT INTO vr_temp_ids (Value)
		SELECT n.poll_id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY p.creation_date DESC, p.poll_id DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY p.creation_date ASC, p.poll_id ASC) AS rev_row_number,
						p.poll_id
				FROM fg_polls AS p
				WHERE p.application_id = vr_application_id AND p.deleted = vr_archive AND
					((vr_isCopyOfPollID IS NULL AND p.is_copy_of_poll_id IS NULL) OR 
					(vr_isCopyOfPollID IS NOT NULL AND p.is_copy_of_poll_id = vr_isCopyOfPollID)) AND
					((vr_owner_id IS NULL AND p.owner_id IS NULL) OR 
					(vr_owner_id IS NOT NULL AND p.owner_id = vr_owner_id))
			) AS n
		ORDER BY n.row_number ASC
	END
	ELSE BEGIN
		INSERT INTO vr_temp_ids (Value)
		SELECT n.poll_id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY srch.rank DESC, srch.key DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY srch.rank ASC, srch.key ASC) AS rev_row_number,
						p.poll_id
				FROM CONTAINSTABLE(fg_polls, (name), vr_searchText) AS srch
					INNER JOIN fg_polls AS p
					ON srch.key = p.poll_id
				WHERE p.application_id = vr_application_id AND p.deleted = vr_archive AND
					((vr_isCopyOfPollID IS NULL AND p.is_copy_of_poll_id IS NULL) OR 
					(vr_isCopyOfPollID IS NOT NULL AND p.is_copy_of_poll_id = vr_isCopyOfPollID)) AND
					((vr_owner_id IS NULL AND p.owner_id IS NULL) OR 
					(vr_owner_id IS NOT NULL AND p.owner_id = vr_owner_id))
			) AS n
		ORDER BY n.row_number ASC
	END
	
	DECLARE vr_poll_ids KeyLessGuidTableType
	
	INSERT INTO vr_poll_ids (Value)
	SELECT TOP(vr_count) i_ds.value
	FROM vr_temp_ids AS i_ds
	WHERE i_ds.sequence_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY i_ds.sequence_number ASC
	
	EXEC fg_p_get_polls_by_ids vr_application_id, vr_poll_ids
	
	SELECT TOP(1) COUNT(t.value) AS total_count 
	FROM vr_temp_ids AS t
END;


DROP PROCEDURE IF EXISTS fg_p_add_poll;

CREATE PROCEDURE fg_p_add_poll
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_copy_from_poll_id	UUID,
	vr_owner_id		UUID,
	vr_name		 VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_poll_id = vr_copy_from_poll_id BEGIN
		SET vr__result = -1
		RETURN
	END
	
	SET vr_name = gfn_verify_string(vr_name)
	
	INSERT INTO fg_polls (
		ApplicationID,
		PollID,
		IsCopyOfPollID,
		OwnerID,
		Name,
		ShowSummary,
		HideContributors,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	vr_application_id, 
			vr_poll_id, 
			vr_copy_from_poll_id, 
			vr_owner_id,
			vr_name, 
			COALESCE(p.show_summary, 1),
			COALESCE(p.hide_contributors, 0),
			vr_current_user_id, 
			vr_now,
			0
	FROM (SELECT vr_copy_from_poll_id AS id) AS ref
		LEFT JOIN fg_polls AS p
		ON p.application_id = vr_application_id AND p.poll_id = ref.id
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_add_poll;

CREATE PROCEDURE fg_add_poll
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_copy_from_poll_id	UUID,
	vr_owner_id		UUID,
	vr_name		 VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER = 0
	
	EXEC fg_p_add_poll vr_application_id, vr_poll_id, vr_copy_from_poll_id, 
		vr_owner_id, vr_name, vr_current_user_id, vr_now, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS fg_get_poll_instance;

CREATE PROCEDURE fg_get_poll_instance
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_copy_from_poll_id	UUID,
	vr_owner_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER = 0
	
	IF NOT EXISTS (
		SELECT TOP(1) 1
		FROM fg_polls
		WHERE PollID = vr_poll_id
	) BEGIN
		EXEC fg_p_add_poll vr_application_id, vr_poll_id, vr_copy_from_poll_id, 
			vr_owner_id, NULL, vr_current_user_id, vr_now, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT NULL
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE vr_form_id UUID = (
		SELECT TOP(1) fo.form_id
		FROM fg_polls AS p
			INNER JOIN fg_form_owners AS fo
			ON fo.application_id = vr_application_id AND 
				fo.owner_id = p.poll_id AND fo.deleted = FALSE
		WHERE p.application_id = vr_application_id AND p.poll_id = vr_copy_from_poll_id
	)
	
	IF vr_form_id IS NULL BEGIN
		SELECT NULL
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr_instanceID UUID = (
		SELECT TOP(1) fi.instance_id
		FROM fg_form_instances AS fi
		WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND
			fi.director_id = vr_current_user_id AND fi.deleted = FALSE
		ORDER BY fi.creation_date DESC
	)
	
	IF vr_instanceID IS NULL BEGIN
		SET vr_instanceID = gen_random_uuid()
	
		SET vr__result = 0
		
		DECLARE vr_instances FormInstanceTableType
			
		INSERT INTO vr_instances (InstanceID, FormID, OwnerID, DirectorID, admin)
		VALUES (vr_instanceID, vr_form_id, vr_poll_id, vr_current_user_id, 0)
		
		EXEC fg_p_create_form_instance vr_application_id, vr_instances, vr_current_user_id, vr_now, vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT NULL
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT vr_instanceID
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS fg_get_owner_poll_ids;

CREATE PROCEDURE fg_get_owner_poll_ids
	vr_application_id	UUID,
	vr_isCopyOfPollID	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT PollID AS id
	FROM fg_polls
	WHERE ApplicationID = vr_application_id AND IsCopyOfPollID = vr_isCopyOfPollID AND 
		OwnerID = vr_owner_id AND deleted = FALSE
	ORDER BY CreationDate DESC
END;


DROP PROCEDURE IF EXISTS fg_rename_poll;

CREATE PROCEDURE fg_rename_poll
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_name		 VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	
	UPDATE fg_polls
		SET Name = vr_name,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_poll_description;

CREATE PROCEDURE fg_set_poll_description
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_description VARCHAR(2000),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE fg_polls
		SET description = vr_description,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_poll_begin_date;

CREATE PROCEDURE fg_set_poll_begin_date
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_beginDate	 TIMESTAMP,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_polls
		SET BeginDate = vr_beginDate,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_poll_finish_date;

CREATE PROCEDURE fg_set_poll_finish_date
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_finish_date	 TIMESTAMP,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_polls
		SET FinishDate = vr_finish_date,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_poll_show_summary;

CREATE PROCEDURE fg_set_poll_show_summary
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_showSummary BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_polls
		SET ShowSummary = COALESCE(vr_showSummary, 0),
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_set_poll_hide_contributors;

CREATE PROCEDURE fg_set_poll_hide_contributors
	vr_application_id		UUID,
	vr_poll_id				UUID,
	vr_hide_contributors BOOLEAN,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_polls
		SET HideContributors = COALESCE(vr_hide_contributors, 0),
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_remove_poll;

CREATE PROCEDURE fg_remove_poll
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_polls
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_recycle_poll;

CREATE PROCEDURE fg_recycle_poll
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE fg_polls
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND PollID = vr_poll_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS fg_get_poll_status;

CREATE PROCEDURE fg_get_poll_status
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_isCopyOfPollID	UUID,
	vr_current_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_description VARCHAR(2000)
	DECLARE vr_beginDate TIMESTAMP
	DECLARE vr_finish_date TIMESTAMP
	DECLARE vr_instanceID UUID
	DECLARE vr_elementsCount INTEGER
	DECLARE vr_filledElementsCount INTEGER
	DECLARE vr_allFilledFormsCount INTEGER

	IF vr_poll_id IS NULL BEGIN
		SELECT TOP(1) 
			vr_description = p.description
		FROM fg_polls AS p
		WHERE p.application_id = vr_application_id AND p.poll_id = vr_isCopyOfPollID
	END
	ELSE BEGIN
		SELECT TOP(1) 
			vr_description = COALESCE(p.description, ref.description), 
			vr_beginDate = p.begin_date,
			vr_finish_date = p.finish_date,
			vr_instanceID = fi.instance_id
		FROM fg_polls AS p
			INNER JOIN fg_polls AS ref
			ON ref.application_id = vr_application_id AND ref.poll_id = p.is_copy_of_poll_id
			INNER JOIN fg_form_owners AS fo
			ON fo.application_id = vr_application_id AND fo.owner_id = ref.poll_id AND fo.deleted = FALSE
			LEFT JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.form_id = fo.form_id AND 
				fi.owner_id = vr_poll_id AND fi.director_id = vr_current_user_id
		WHERE p.application_id = vr_application_id AND p.poll_id = vr_poll_id
		ORDER BY fi.creation_date DESC
	END

	DECLARE vr_limited_elements GuidTableType
	
	INSERT INTO vr_limited_elements (Value)
	SELECT ref.element_id
	FROM fg_fn_get_limited_elements(vr_application_id, vr_isCopyOfPollID) AS ref
	
	SELECT TOP(1)	
		vr_elementsCount = COUNT(DISTINCT l.value),
		vr_filledElementsCount = COUNT(DISTINCT ie.element_id)
	FROM vr_limited_elements AS l
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = l.value AND
			fg_fn_is_fillable(efe.type) = 1
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.instance_id = vr_instanceID AND 
			ie.ref_element_id = l.value AND ie.deleted = FALSE AND
			COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, 
				ie.type, ie.text_value, ie.float_value, ie.bit_value, ie.date_value), N'') <> N''

	SELECT vr_allFilledFormsCount = COUNT(DISTINCT fi.director_id)
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND
			COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value), N'') <> N''
		INNER JOIN vr_limited_elements AS l
		ON l.value = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE
			
	SELECT	vr_description AS description,
			vr_beginDate AS begin_date,
			vr_finish_date AS finish_date,
			vr_instanceID AS instance_id,
			vr_elementsCount AS elements_count, 
			vr_filledElementsCount AS filled_elements_count,
			vr_allFilledFormsCount AS all_filled_forms_count
END;


DROP PROCEDURE IF EXISTS fg_get_poll_elements_instance_count;

CREATE PROCEDURE fg_get_poll_elements_instance_count
	vr_application_id	UUID,
	vr_poll_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_isCopyOfPollID UUID = (
		SELECT TOP(1) IsCopyOfPollID
		FROM fg_polls
		WHERE PollID = vr_poll_id
	)

	IF vr_isCopyOfPollID IS NULL RETURN

	SELECT ie.ref_element_id AS id, COUNT(DISTINCT fi.director_id) AS count
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND
			COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value), N'') <> N''
		INNER JOIN (
			SELECT ref.element_id
			FROM fg_fn_get_limited_elements(vr_application_id, vr_isCopyOfPollID) AS ref
		) AS e
		ON e.element_id = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND 
		fi.owner_id = vr_poll_id AND fi.deleted = FALSE
	GROUP BY ie.ref_element_id
END;


DROP PROCEDURE IF EXISTS fg_get_poll_abstract_text;

CREATE PROCEDURE fg_get_poll_abstract_text
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char,
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_temp Table(ElementID UUID, Value VARCHAR(max), Number float,
		Seq INTEGER IDENTITY(1,1) primary key clustered)
	DECLARE vr_tbl Table(ElementID UUID, Value VARCHAR(max), Number float)

	INSERT INTO vr_temp (ElementID, Value, Number)
	SELECT i_ds.value, ie.text_value, ie.float_value
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND
			LTRIM(RTRIM(COALESCE(ie.text_value, N''))) <> N''
		INNER JOIN vr_element_ids AS i_ds
		ON i_ds.value = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE

	DECLARE vr_cur INTEGER = (SELECT MAX(Seq) FROM vr_temp)

	WHILE vr_cur > 0 BEGIN
		DECLARE vr_eid UUID
		DECLARE vr_val VARCHAR(max)
		DECLARE vr_num float
		
		SELECT TOP(1) vr_eid = t.element_id, vr_val = t.value, vr_num = t.number
		FROM vr_temp AS t
		WHERE t.seq = vr_cur

		INSERT INTO vr_tbl (ElementID, Value, Number)
		SELECT vr_eid, ref.value, vr_num
		FROM gfn_str_to_string_table(vr_val, N'~') AS ref
		
		SET vr_cur = vr_cur - 1
	END

	SELECT TOP(COALESCE(vr_count, 5))
		CAST((v.row_number + v.rev_row_number - 1) AS integer) AS total_values_count,
		v.element_id,
		v.value,
		v.count
	FROM (
			SELECT	ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count DESC, x.value DESC) AS row_number,
					ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count ASC, x.value ASC) AS rev_row_number,
					x.*
			FROM (
					SELECT t.element_id, t.value, COUNT(t.element_id) AS count
					FROM vr_tbl AS t
					GROUP BY t.element_id, t.value
				) AS x
		) AS v
	WHERE v.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY v.row_number ASC
	
	SELECT	t.element_id, 
			MIN(t.number) AS min, 
			MAX(t.number) AS max, 
			AVG(t.number) AS avg, 
			COALESCE(VAR(t.number), 0) AS var, 
			COALESCE(STDEV(t.number), 0) AS st_dev
	FROM vr_tbl AS t
	WHERE t.number IS NOT NULL
	GROUP BY t.element_id
END;


DROP PROCEDURE IF EXISTS fg_get_poll_abstract_guid;

CREATE PROCEDURE fg_get_poll_abstract_guid
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char,
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_tbl Table(ElementID UUID, Value UUID)

	INSERT INTO vr_tbl (ElementID, Value)
	SELECT i_ds.value, s.selected_id
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE
		INNER JOIN vr_element_ids AS i_ds
		ON i_ds.value = ie.ref_element_id
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND s.element_id = ie.element_id AND s.deleted = FALSE
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE

	SELECT TOP(COALESCE(vr_count, 5))
		CAST((v.row_number + v.rev_row_number - 1) AS integer) AS total_values_count,
		v.element_id,
		v.value,
		v.count
	FROM (
			SELECT	ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count DESC, x.value DESC) AS row_number,
					ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count ASC, x.value ASC) AS rev_row_number,
					x.*
			FROM (
					SELECT t.element_id, t.value, COUNT(t.element_id) AS count
					FROM vr_tbl AS t
					GROUP BY t.element_id, t.value
				) AS x
		) AS v
	WHERE v.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY v.row_number ASC
END;


DROP PROCEDURE IF EXISTS fg_get_poll_abstract_bool;

CREATE PROCEDURE fg_get_poll_abstract_bool
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_tbl Table(ElementID UUID, Value BOOLEAN)

	INSERT INTO vr_tbl (ElementID, Value)
	SELECT i_ds.value, ie.bit_value
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND ie.bit_value IS NOT NULL
		INNER JOIN vr_element_ids AS i_ds
		ON i_ds.value = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE

	SELECT t.element_id, t.value, COUNT(t.element_id) AS count, NULL AS total_values_count
	FROM vr_tbl AS t
	GROUP BY t.element_id, t.value
END;


DROP PROCEDURE IF EXISTS fg_get_poll_abstract_number;

CREATE PROCEDURE fg_get_poll_abstract_number
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_strElementIDs	varchar(max),
	vr_delimiter		char,
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_element_ids GuidTableType
	
	INSERT INTO vr_element_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strElementIDs, vr_delimiter) AS ref
	
	DECLARE vr_tbl Table(ElementID UUID, Value float)

	INSERT INTO vr_tbl (ElementID, Value)
	SELECT i_ds.value, ie.float_value
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND ie.float_value IS NOT NULL
		INNER JOIN vr_element_ids AS i_ds
		ON i_ds.value = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE

	SELECT TOP(COALESCE(vr_count, 5))
		CAST((v.row_number + v.rev_row_number - 1) AS integer) AS total_values_count,
		v.element_id,
		CAST(v.value AS float) AS value,
		v.count
	FROM (
			SELECT	ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count DESC, x.value DESC) AS row_number,
					ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count ASC, x.value ASC) AS rev_row_number,
					x.*
			FROM (
					SELECT t.element_id, t.value, COUNT(t.element_id) AS count
					FROM vr_tbl AS t
					GROUP BY t.element_id, t.value
				) AS x
		) AS v
	WHERE v.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY v.row_number ASC
	
	SELECT	t.element_id, 
			MIN(t.value) AS min, 
			MAX(t.value) AS max, 
			AVG(t.value) AS avg, 
			COALESCE(VAR(t.value), 0) AS var, 
			COALESCE(STDEV(t.value), 0) AS st_dev
	FROM vr_tbl AS t
	GROUP BY t.element_id
END;


DROP PROCEDURE IF EXISTS fg_get_poll_element_instances;

CREATE PROCEDURE fg_get_poll_element_instances
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_element_id		UUID,
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 20)) *
	FROM (
			SELECT	ROW_NUMBER() OVER(ORDER BY COALESCE(ie.last_modification_date, ie.creation_date) DESC, 
						ie.element_id DESC) AS row_number,
					un.user_id,
					un.username,
					un.first_name,
					un.last_name,
					ie.element_id,
					ie.ref_element_id,
					ie.type,
					COALESCE(ie.text_value, N'') AS text_value,
					ie.float_value,
					ie.bit_value,
					ie.date_value,
					ie.creation_date,
					ie.last_modification_date
			FROM fg_form_instances AS fi
				INNER JOIN fg_instance_elements AS ie
				ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND
					ie.ref_element_id = vr_element_id AND ie.deleted = FALSE AND
					COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
						ie.text_value, ie.float_value, ie.bit_value, ie.date_value), N'') <> N''
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = fi.director_id
			WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND 
				fi.director_id IS NOT NULL AND fi.deleted = FALSE
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
END;


DROP PROCEDURE IF EXISTS fg_get_current_polls_count;

CREATE PROCEDURE fg_get_current_polls_count
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP,
	vr_default_privacy	varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_poll_ids KeyLessGuidTableType

	INSERT INTO vr_poll_ids (Value)
	SELECT p.poll_id
	FROM fg_polls AS p
	WHERE p.application_id = vr_application_id AND 
		p.is_copy_of_poll_id IS NOT NULL AND p.owner_id IS NULL AND p.deleted = FALSE AND 
		(p.begin_date IS NOT NULL OR p.finish_date IS NOT NULL) AND
		(p.begin_date IS NULL OR p.begin_date <= vr_now) AND
		(p.finish_date IS NULL OR p.finish_date >= vr_now)
		
	DECLARE	vr_permission_types StringPairTableType
	
	INSERT INTO vr_permission_types (FirstValue, SecondValue)
	VALUES (N'View', vr_default_privacy)

	SELECT	CAST(COUNT(x.poll_id) AS integer) AS count,
			CAST(SUM(x.done) AS integer) AS done_count
	FROM (
			SELECT	p.poll_id,
					MAX(CAST((CASE WHEN fi.instance_id IS NULL THEN 0 ELSE 1 END) AS integer)) AS done
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_poll_ids, N'Poll', vr_now, vr_permission_types) AS i_ds
				INNER JOIN fg_polls AS p
				ON p.application_id = vr_application_id AND p.poll_id = i_ds.id
				LEFT JOIN fg_form_instances AS fi
				ON fi.application_id = vr_application_id AND fi.owner_id = i_ds.id AND
					fi.director_id = vr_current_user_id AND fi.deleted = FALSE
			GROUP BY p.poll_id
		) AS x
END;


DROP PROCEDURE IF EXISTS fg_get_current_polls;

CREATE PROCEDURE fg_get_current_polls
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP,
	vr_default_privacy	varchar(50),
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_poll_ids KeyLessGuidTableType

	INSERT INTO vr_poll_ids (Value)
	SELECT p.poll_id
	FROM fg_polls AS p
	WHERE p.application_id = vr_application_id AND
		p.is_copy_of_poll_id IS NOT NULL AND p.owner_id IS NULL AND p.deleted = FALSE AND 
		(p.begin_date IS NOT NULL OR p.finish_date IS NOT NULL) AND
		(p.begin_date IS NULL OR p.begin_date <= vr_now) AND
		(p.finish_date IS NULL OR p.finish_date >= vr_now)
	
	DECLARE	vr_permission_types StringPairTableType
	
	INSERT INTO vr_permission_types (FirstValue, SecondValue)
	VALUES (N'View', vr_default_privacy)

	SELECT TOP(COALESCE(vr_count, 20)) x.id, x.done AS value, x.row_number + x.rev_row_number - 1 AS total_count
	FROM (
			SELECT	ROW_NUMBER() OVER(ORDER BY MAX(p.begin_date) DESC, MAX(p.finish_date) ASC) AS row_number,
					ROW_NUMBER() OVER(ORDER BY MAX(p.begin_date) ASC, MAX(p.finish_date) DESC) AS rev_row_number,
					i_ds.id, 
					CAST((CASE WHEN COUNT(fi.instance_id) > 0 THEN 1 ELSE 0 END) AS boolean) AS done
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_poll_ids, N'Poll', vr_now, vr_permission_types) AS i_ds
				INNER JOIN fg_polls AS p
				ON p.application_id = vr_application_id AND p.poll_id = i_ds.id
				LEFT JOIN fg_form_instances AS fi
				ON fi.application_id = vr_application_id AND fi.owner_id = i_ds.id AND
					fi.director_id = vr_current_user_id AND fi.deleted = FALSE
			GROUP BY i_ds.id
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
END;


DROP PROCEDURE IF EXISTS fg_is_poll;

CREATE PROCEDURE fg_is_poll
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ref.value AS id
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
		INNER JOIN fg_polls AS p
		ON p.application_id = vr_application_id AND p.poll_id = ref.value
END;


-- end of Polls

DROP PROCEDURE IF EXISTS rv_get_system_version;

CREATE PROCEDURE rv_get_system_version
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) version
	FROM app_setting
END;


DROP PROCEDURE IF EXISTS rv_set_applications;

CREATE PROCEDURE rv_set_applications
	vr_applicationsTemp	GuidStringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_applications GuidStringTableType
	INSERT INTO vr_applications SELECT * FROM vr_applicationsTemp
	
	DECLARE vr_count INTEGER = 0
	
	UPDATE APP
		SET ApplicationName = a.second_value,
			LoweredApplicationName = LOWER(a.second_value)
	FROM vr_applications AS a
		INNER JOIN rv_applications AS app
		ON app.application_id = a.first_value
		
	SET vr_count = @vr_rowcount
		
	INSERT INTO rv_applications(
		ApplicationId,
		ApplicationName,
		LoweredApplicationName
	)
	SELECT a.first_value, a.second_value, LOWER(a.second_value)
	FROM vr_applications AS a
		LEFT JOIN rv_applications AS app
		ON app.application_id = a.first_value
	WHERE app.application_id IS NULL
	
	SELECT @vr_rowcount + vr_count
END;


DROP PROCEDURE IF EXISTS rv_get_applications_by_ids;

CREATE PROCEDURE rv_get_applications_by_ids
	vr_strApplicationIDs	varchar(max),
	vr_delimiter			char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_application_ids GuidTableType

	INSERT INTO vr_application_ids (value) 
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strApplicationIDs, vr_delimiter) AS ref
	
	DECLARE vr_total_count INTEGER  = COALESCE((SELECT TOP(1) COUNT(*) FROM vr_application_ids), 0)
	
	SELECT 
		vr_total_count AS total_count,
		a.application_id,
		a.application_name,
		a.title,
		a.description,
		a.creator_user_id
	FROM vr_application_ids AS i_ds
		INNER JOIN rv_applications AS a
		ON a.application_id = i_ds.value
END;


DROP PROCEDURE IF EXISTS rv_get_applications;

CREATE PROCEDURE rv_get_applications
	vr_count		 INTEGER,
	vr_lower_boundary INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 100))
		x.row_number + x.rev_row_number - 1 AS total_count,
		x.application_id,
		x.application_name,
		x.title,
		x.description,
		x.creator_user_id
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY ApplicationID DESC) AS row_number,
					ROW_NUMBER() OVER (ORDER BY ApplicationID ASC) AS rev_row_number,
					ApplicationId AS application_id,
					ApplicationName,
					Title,
					description,
					CreatorUserID
			FROM rv_applications
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
END;


DROP PROCEDURE IF EXISTS rv_get_user_applications;

CREATE PROCEDURE rv_get_user_applications
	vr_user_id		UUID,
	vr_isCreator BOOLEAN,
	vr_archive BOOLEAN
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_isCreator = COALESCE(vr_isCreator, 0)
	
	SELECT	0 AS total_count,
			app.application_id AS application_id,
			app.application_name,
			app.title,
			app.description,
			CreatorUserID
	FROM usr_user_applications AS usr
		INNER JOIN rv_applications AS app
		ON app.application_id = usr.application_id AND 
			(vr_isCreator = 0 OR app.creator_user_id = vr_user_id) AND
			(vr_archive IS NULL OR COALESCE(app.deleted, FALSE) = vr_archive)
	WHERE usr.user_id = vr_user_id
END;


DROP PROCEDURE IF EXISTS rv_add_or_modify_application;

CREATE PROCEDURE rv_add_or_modify_application
	vr_application_id	UUID,
	vr_name		 VARCHAR(255),
	vr_title		 VARCHAR(255),
	vr_description VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM rv_applications AS a
		WHERE a.application_id = vr_application_id
	) BEGIN
		UPDATE rv_applications
			SET Title = gfn_verify_string(COALESCE(vr_title, N'')),
				description = gfn_verify_string(COALESCE(vr_description, N''))
		WHERE ApplicationId = vr_application_id	
	END
	ELSE BEGIN
		INSERT INTO rv_applications(
			ApplicationId,
			ApplicationName,
			LoweredApplicationName,
			Title,
			description,
			CreatorUserID,
			CreationDate
		)
		VALUES (
			vr_application_id,
			gfn_verify_string(COALESCE(vr_name, N'')),
			gfn_verify_string(COALESCE(vr_name, N'')),
			gfn_verify_string(COALESCE(vr_title, N'')),
			gfn_verify_string(COALESCE(vr_description, N'')),
			vr_current_user_id,
			vr_now
		)
		
		IF vr_current_user_id IS NOT NULL AND vr_application_id IS NOT NULL BEGIN
			INSERT INTO usr_user_applications (ApplicationID, UserID, CreationDate)
			VALUES (vr_application_id, vr_current_user_id, vr_now)
		END
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_remove_application;

CREATE PROCEDURE rv_remove_application
	vr_application_id	UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	UPDATE rv_applications
		SET deleted = TRUE
	WHERE ApplicationId = vr_application_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_recycle_application;

CREATE PROCEDURE rv_recycle_application
	vr_application_id	UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	UPDATE rv_applications
		SET deleted = FALSE
	WHERE ApplicationId = vr_application_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_add_user_to_application;

CREATE PROCEDURE rv_add_user_to_application
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_application_id IS NOT NULL AND vr_user_id IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) *
		FROM usr_user_applications
		WHERE ApplicationID = vr_application_id AND UserID = vr_user_id
	) BEGIN
		INSERT INTO usr_user_applications (ApplicationID, UserID, CreationDate)
		VALUES (vr_application_id, vr_user_id, vr_now)
	END
	
	SELECT CASE WHEN vr_application_id IS NULL OR vr_user_id IS NULL THEN 0 ELSE 1 END
END;


DROP PROCEDURE IF EXISTS rv_remove_user_from_application;

CREATE PROCEDURE rv_remove_user_from_application
	vr_application_id	UUID,
	vr_user_id			UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DELETE usr_user_applications
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_set_variable;

CREATE PROCEDURE rv_set_variable
	vr_application_id	UUID,
	vr_name			VARCHAR(100),
	vr_value		 VARCHAR(MAX),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = LOWER(vr_name)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM rv_variables 
		WHERE (vr_application_id IS NULL OR ApplicationID = vr_application_id) AND Name = vr_name
	) BEGIN
		UPDATE rv_variables
			SET Value = vr_value,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		WHERE (vr_application_id IS NULL OR ApplicationID = vr_application_id) AND Name = vr_name
	END
	ELSE BEGIN
		INSERT INTO rv_variables(
			ApplicationID,
			Name,
			Value,
			LastModifierUserID,
			LastModificationDate
		)
		VALUES(
			vr_application_id,
			vr_name,
			vr_value,
			vr_current_user_id,
			vr_now
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_get_variable;

CREATE PROCEDURE rv_get_variable
	vr_application_id	UUID,
	vr_name			varchar(100)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = LOWER(vr_name)
	
	SELECT TOP(1) Value
	FROM rv_variables
	WHERE (vr_application_id IS NULL OR ApplicationID = vr_application_id) AND Name = vr_name
END;


DROP PROCEDURE IF EXISTS rv_set_owner_variable;

CREATE PROCEDURE rv_set_owner_variable
	vr_application_id	UUID,
	vr_iD				bigint,
	vr_owner_id		UUID,
	vr_name			VARCHAR(100),
	vr_value		 VARCHAR(MAX),
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_name IS NOT NULL SET vr_name = LOWER(vr_name)
	
	IF vr_iD IS NOT NULL BEGIN
		UPDATE rv_variables_with_owner
			SET Name = LOWER(CASE WHEN COALESCE(vr_name, N'') = N'' THEN Name ELSE vr_name END),
				Value = vr_value,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		WHERE ApplicationID = vr_application_id AND ID = vr_iD
		
		IF @vr_rowcount > 0 SELECT vr_iD
		ELSE SELECT NULL
	END
	ELSE BEGIN
		INSERT INTO rv_variables_with_owner (
			ApplicationID,
			OwnerID,
			Name,
			Value,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			vr_application_id,
			vr_owner_id,
			LOWER(vr_name),
			vr_value,
			vr_current_user_id,
			vr_now,
			0
		)
		
		SELECT @vr_iDENTITY
	END
END;


DROP PROCEDURE IF EXISTS rv_get_owner_variables;

CREATE PROCEDURE rv_get_owner_variables
	vr_application_id	UUID,
	vr_iD				bigint,
	vr_owner_id		UUID,
	vr_name			varchar(100),
	vr_creator_user_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = LOWER(vr_name)
	
	SELECT	ID,
			OwnerID,
			Name,
			Value,
			CreatorUserID,
			CreationDate
	FROM rv_variables_with_owner
	WHERE ApplicationID = vr_application_id AND (vr_iD IS NULL OR ID = vr_iD) AND 
		(vr_owner_id IS NULL OR OwnerID = vr_owner_id) AND (vr_name IS NULL OR Name = vr_name) AND 
		(vr_creator_user_id IS NULL OR CreatorUserID = vr_creator_user_id) AND deleted = FALSE
	ORDER BY ID ASC
END;


DROP PROCEDURE IF EXISTS rv_remove_owner_variable;

CREATE PROCEDURE rv_remove_owner_variable
	vr_application_id	UUID,
	vr_iD				bigint,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE rv_variables_with_owner
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND ID = vr_iD
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_add_emails_to_queue;

CREATE PROCEDURE rv_add_emails_to_queue
	vr_application_id			UUID,
	vr_emailQueueItemsTemp	EmailQueueItemTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_emailQueueItems EmailQueueItemTableType
	INSERT INTO vr_emailQueueItems SELECT * FROM vr_emailQueueItemsTemp
	
	UPDATE Q
		SET Title = e.title,
			EmailBody = e.email_body
	FROM vr_emailQueueItems AS e
		INNER JOIN rv_email_queue AS q
		ON q.application_id = vr_application_id AND q.sender_user_id = e.sender_user_id AND 
			q.action = e.action AND q.email = LOWER(e.email)
	
	DECLARE vr_result INTEGER = @vr_rowcount
	
	INSERT INTO rv_email_queue(
		ApplicationID,
		SenderUserID,
		action,
		Email,
		Title,
		EmailBody
	)
	SELECT vr_application_id, e.sender_user_id, e.action, LOWER(e.email), e.title, e.emailBody
	FROM vr_emailQueueItems AS e
		LEFT JOIN rv_email_queue AS q
		ON q.application_id = vr_application_id AND 
			q.sender_user_id = e.sender_user_id AND q.action = e.action AND q.email = e.email
	WHERE q.id IS NULL
	
	SELECT @vr_rowcount + vr_result
END;


DROP PROCEDURE IF EXISTS rv_get_email_queue_items;

CREATE PROCEDURE rv_get_email_queue_items
	vr_application_id	UUID,
	vr_count		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 100))
			e.id,
			e.sender_user_id,
			e.action,
			e.email,
			e.title,
			e.email_body
	FROM rv_email_queue AS e
	WHERE ApplicationID = vr_application_id
	ORDER BY e.id ASC
END;


DROP PROCEDURE IF EXISTS rv_archive_email_queue_items;

CREATE PROCEDURE rv_archive_email_queue_items
	vr_application_id	UUID,
	vr_itemIDsTemp	BigIntTableType readonly,
	vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_itemIDs BigIntTableType
	INSERT INTO vr_itemIDs SELECT * FROM vr_itemIDsTemp
	
	INSERT INTO rv_sent_emails(
		ApplicationID,
		SenderUserID,
		SendDate,
		action,
		Email,
		Title,
		EmailBody
	)
	SELECT vr_application_id, e.sender_user_id, vr_now, e.action, e.email, e.title, e.emailBody
	FROM vr_itemIDs AS i_ds
		INNER JOIN rv_email_queue AS e
		ON e.application_id = vr_application_id AND e.id = i_ds.value
		
		
	DELETE E
	FROM vr_itemIDs AS i_ds
		INNER JOIN rv_email_queue AS e
		ON e.application_id = vr_application_id AND e.id = i_ds.value
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_p_set_deleted_states;

CREATE PROCEDURE rv_p_set_deleted_states
	vr_application_id	UUID,
	vr_objects_temp	GuidBitTableType readonly,
	vr_object_type		varchar(50),
	vr_now		 TIMESTAMP,
	vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_objects GuidBitTableType
	INSERT INTO vr_objects SELECT * FROM vr_objects_temp
	
	IF vr_now IS NULL SET vr_now = GETDATE()
	
	DELETE D
	FROM vr_objects AS o
		INNER JOIN rv_deleted_states AS d
		ON d.application_id = vr_application_id AND d.object_id = o.first_value
		
	INSERT INTO rv_deleted_states(ApplicationID, ObjectID, ObjectType, Deleted, date)
	SELECT vr_application_id, o.first_value, vr_object_type, o.second_value, vr_now
	FROM vr_objects AS o
		
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_get_deleted_states;

CREATE PROCEDURE rv_get_deleted_states
	vr_application_id	UUID,
	vr_count		 INTEGER,
	vr_startFrom		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE(vr_count, 0) < 1 SET vr_count = 1000
	
	SELECT TOP(vr_count)
		d.id,
		d.object_id,
		d.object_type,
		d.date,
		d.deleted,
		CASE
			WHEN ObjectType = N'NodeRelation' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'Friend' AND fr.are_friends = TRUE THEN CAST(1 AS boolean)
			ELSE CAST(0 AS boolean)
		END AS bidirectional,
		CASE
			WHEN ObjectType = N'Friend' AND fr.are_friends = FALSE THEN CAST(1 AS boolean)
			WHEN ObjectType = N'NodeMember' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'Expert' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'NodeLike' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'ItemVisit' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'NodeCreator' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'TaggedItem' THEN CAST(1 AS boolean)
			WHEN ObjectType = N'WikiChange' THEN CAST(1 AS boolean)
			ELSE CAST(0 AS boolean)
		END AS has_reverse,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN nc.node_id
			WHEN ObjectType = N'NodeRelation' THEN nr.source_node_id
			WHEN ObjectType = N'NodeMember' THEN nm.node_id
			WHEN ObjectType = N'Expert' THEN ex.node_id
			WHEN ObjectType = N'NodeLike' THEN nl.node_id
			WHEN ObjectType = N'ItemVisit' THEN iv.item_id
			WHEN ObjectType = N'Friend' THEN fr.sender_user_id
			WHEN ObjectType = N'WikiChange' THEN wt.owner_id
			WHEN ObjectType = N'TaggedItem' AND ti.context_type = N'WikiChange' THEN tgwt.owner_id
			WHEN ObjectType = N'TaggedItem' AND ti.context_type = N'Post' THEN tgps.owner_id
			WHEN ObjectType = N'TaggedItem' AND ti.context_type = N'Comment' THEN tgps2.owner_id
			ELSE NULL
		END AS rel_source_id,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN nc.user_id
			WHEN ObjectType = N'NodeRelation' THEN nr.destination_node_id
			WHEN ObjectType = N'NodeMember' THEN nm.user_id
			WHEN ObjectType = N'Expert' THEN ex.user_id
			WHEN ObjectType = N'NodeLike' THEN nl.user_id
			WHEN ObjectType = N'ItemVisit' THEN iv.user_id
			WHEN ObjectType = N'Friend' THEN fr.receiver_user_id
			WHEN ObjectType = N'WikiChange' THEN wc.user_id
			WHEN ObjectType = N'TaggedItem' THEN ti.tagged_id
			ELSE NULL
		END AS rel_destination_id,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN N'Node'
			WHEN ObjectType = N'NodeRelation' THEN N'Node'
			WHEN ObjectType = N'NodeMember' THEN N'Node'
			WHEN ObjectType = N'Expert' THEN N'Node'
			WHEN ObjectType = N'NodeLike' THEN N'Node'
			WHEN ObjectType = N'ItemVisit' AND iv.item_type = N'User' THEN N'User'
			WHEN ObjectType = N'ItemVisit' THEN N'Node'
			WHEN ObjectType = N'Friend' THEN N'User'
			WHEN ObjectType = N'WikiChange' THEN N'Node'
			WHEN ObjectType = N'TaggedItem' AND ti.context_type = N'WikiChange' THEN N'Node'
			WHEN ObjectType = N'TaggedItem' AND tgun.user_id IS NOT NULL THEN N'User'
			WHEN ObjectType = N'TaggedItem' THEN N'Node'
			ELSE NULL
		END AS rel_source_type,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN N'User'
			WHEN ObjectType = N'NodeRelation' THEN N'User'
			WHEN ObjectType = N'NodeMember' THEN N'User'
			WHEN ObjectType = N'Expert' THEN N'User'
			WHEN ObjectType = N'NodeLike' THEN N'User'
			WHEN ObjectType = N'ItemVisit' THEN N'User'
			WHEN ObjectType = N'Friend' THEN N'User'
			WHEN ObjectType = N'WikiChange' THEN N'User'
			WHEN ObjectType = N'TaggedItem' THEN ti.tagged_type
			ELSE NULL
		END AS rel_destination_type,
		CASE
			WHEN ObjectType = N'TaggedItem' THEN ti.creator_user_id
			ELSE NULL
		END AS rel_creator_id
	FROM rv_deleted_states AS d
		LEFT JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.unique_id = d.object_id
		LEFT JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.unique_id = d.object_id
		LEFT JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.unique_id = d.object_id
		LEFT JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND ex.unique_id = d.object_id
		LEFT JOIN cn_node_likes AS nl
		ON nl.application_id = vr_application_id AND nl.unique_id = d.object_id
		LEFT JOIN usr_item_visits AS iv
		ON iv.application_id = vr_application_id AND iv.unique_id = d.object_id
		LEFT JOIN usr_friends AS fr
		ON fr.application_id = vr_application_id AND fr.unique_id = d.object_id
		LEFT JOIN wk_changes AS wc
		ON wc.application_id = vr_application_id AND wc.change_id = d.object_id
		LEFT JOIN wk_paragraphs AS wp
		ON wp.application_id = vr_application_id AND wp.paragraph_id = wc.paragraph_id
		LEFT JOIN wk_titles AS wt
		ON wt.application_id = vr_application_id AND wt.title_id = wp.title_id
		LEFT JOIN rv_tagged_items AS ti
		ON ti.application_id = vr_application_id AND ti.unique_id = d.object_id
		LEFT JOIN wk_paragraphs AS tgwp
		ON tgwp.application_id = vr_application_id AND tgwp.paragraph_id = ti.context_id
		LEFT JOIN wk_titles AS tgwt
		ON tgwt.application_id = vr_application_id AND tgwt.title_id = tgwp.title_id
		LEFT JOIN sh_post_shares AS tgps
		ON tgps.application_id = vr_application_id AND tgps.share_id = ti.context_id
		LEFT JOIN sh_comments AS tgpc
		ON tgpc.application_id = vr_application_id AND tgpc.comment_id = ti.context_id
		LEFT JOIN sh_post_shares AS tgps2
		ON tgps2.application_id = vr_application_id AND tgps2.share_id = tgpc.share_id
		LEFT JOIN users_normal AS tgun
		ON tgun.application_id = vr_application_id AND
			tgun.user_id = tgps.owner_id OR tgun.user_id = tgps2.owner_id
	WHERE d.application_id = vr_application_id AND d.id >= COALESCE(vr_startFrom, 0)
	ORDER BY d.id ASC
END;


DROP PROCEDURE IF EXISTS rv_get_guids;

CREATE PROCEDURE rv_get_guids
	vr_application_id		UUID,
	vr_iDsTemp			StringTableType readonly,
	vr_type				varchar(100),
	vr_exist			 BOOLEAN,
	vr_create_if_not_exist BOOLEAN
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs StringTableType
	INSERT INTO vr_iDs SELECT * FROM vr_iDsTemp
	
	DECLARE vr_tbl TABLE (ID varchar(100), exists BOOLEAN, guid UUID)
	
	INSERT INTO vr_tbl (ID, exists, guid)
	SELECT i.value, (CASE WHEN g.id IS NULL THEN 0 ELSE 1 END), COALESCE(g.guid, gen_random_uuid())
	FROM vr_iDs AS i
		LEFT JOIN rv_id2_guid AS g
		ON g.application_id = vr_application_id AND g.id = i.value AND g.type = vr_type
		
	IF vr_create_if_not_exist = 1 BEGIN
		INSERT INTO rv_id2_guid(ApplicationID, ID, type, guid)
		SELECT vr_application_id, i.id, vr_type, i.guid 
		FROM vr_tbl AS i
		WHERE i.exists = FALSE
	END
	
	SELECT i.id, i.guid
	FROM vr_tbl AS i
	WHERE vr_exist IS NULL OR i.exists = vr_exist
END;


DROP PROCEDURE IF EXISTS rv_save_tagged_items;

CREATE PROCEDURE rv_save_tagged_items
	vr_application_id		UUID,
	vr_tagged_items_temp	TaggedItemTableType readonly,
	vr_remove_old_tags	 BOOLEAN,
	vr_current_user_id		UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tagged_items TaggedItemTableType
	INSERT INTO vr_tagged_items SELECT * FROM vr_tagged_items_temp
	
	IF vr_remove_old_tags = 1 BEGIN
		DELETE TI
		FROM (
				SELECT DISTINCT i.context_id
				FROM vr_tagged_items AS i
			) AS con
			INNER JOIN rv_tagged_items AS ti
			ON ti.application_id = vr_application_id AND ti.context_id = con.context_id
			LEFT JOIN vr_tagged_items AS t
			ON t.context_id = ti.context_id AND t.tagged_id = ti.tagged_id
		WHERE t.context_id IS NULL
	END
	
	INSERT INTO rv_tagged_items(
		ApplicationID,
		ContextID,
		TaggedID,
		CreatorUserID,
		ContextType,
		TaggedType,
		UniqueID
	)
	SELECT vr_application_id, ti.context_id, ti.tagged_id, 
		vr_current_user_id, ti.context_type, ti.tagged_type, gen_random_uuid()
	FROM (
			SELECT DISTINCT * 
			FROM vr_tagged_items
		) AS ti
		LEFT JOIN rv_tagged_items AS t
		ON t.application_id = vr_application_id AND t.context_id = ti.context_id AND 
			t.tagged_id = ti.tagged_id AND t.creator_user_id = vr_current_user_id
	WHERE ti.tagged_id IS NOT NULL AND t.context_id IS NULL
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS rv_get_tagged_items;

CREATE PROCEDURE rv_get_tagged_items
	vr_application_id		UUID,
	vr_context_id			UUID,
	vr_tagged_types_temp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tagged_types StringTableType
	INSERT INTO vr_tagged_types SELECT * FROM vr_tagged_types_temp
	
	DECLARE vr_tagged_typesCount INTEGER = (SELECT COUNT(*) FROM vr_tagged_types)
	
	SELECT	ti.tagged_id AS id,
			ti.tagged_type AS type
	FROM rv_tagged_items AS ti
	WHERE ti.application_id = vr_application_id AND ti.context_id = vr_context_id AND
		(vr_tagged_typesCount = 0 OR ti.tagged_type IN (SELECT Value FROM vr_tagged_types))
END;


DROP PROCEDURE IF EXISTS rv_add_system_admin;

CREATE PROCEDURE rv_add_system_admin
	vr_application_id		UUID,
	vr_user_id				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_adminRoleID UUID = (
		SELECT TOP(1) RoleID
		FROM rv_roles
		WHERE ApplicationID = vr_application_id AND LoweredRoleName = N'admins'
	)

	IF vr_adminRoleID IS NULL BEGIN
		SET vr_adminRoleID = gen_random_uuid()
	
		INSERT INTO rv_roles (
			ApplicationID,
			RoleID,
			RoleName,
			LoweredRoleName
		)
		VALUES (
			vr_application_id,
			vr_adminRoleID,
			N'Admins',
			N'admins'
		)
	END
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM rv_users_in_roles
		WHERE UserId = vr_user_id AND RoleId = vr_adminRoleID
	) BEGIN
		SELECT 1
	END
	ELSE BEGIN
		INSERT INTO rv_users_in_roles (UserID, RoleID)
		VALUES (vr_user_id, vr_adminRoleID)
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS rv_is_system_admin;

CREATE PROCEDURE rv_is_system_admin
	vr_application_id		UUID,
	vr_user_id				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT gfn_is_system_admin(vr_application_id, vr_user_id)
END;


DROP PROCEDURE IF EXISTS rv_get_file_extension;

CREATE PROCEDURE rv_get_file_extension
	vr_application_id		UUID,
	vr_file_id				UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) f.extension AS value
	FROM dct_files AS f
	WHERE f.application_id = vr_application_id AND 
		(f.id = vr_file_id OR f.file_name_guid = vr_file_id)
END;


DROP PROCEDURE IF EXISTS rv_like_dislike_unlike;

CREATE PROCEDURE rv_like_dislike_unlike
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_likedID			UUID,
	vr_like			 BOOLEAN,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_like IS NULL BEGIN
		DELETE rv_likes
		WHERE ApplicationID = vr_application_id AND UserID = vr_user_id AND LikedID = vr_likedID
	END
	ELSE BEGIN
		UPDATE rv_likes
			SET like = vr_like,
				ActionDate = COALESCE(ActionDate, vr_now)
		WHERE ApplicationID = vr_application_id AND 
			UserID = vr_user_id AND LikedID = vr_likedID
			
		IF @vr_rowcount = 0 BEGIN
			INSERT INTO rv_likes (
				ApplicationID,
				UserID,
				LikedID,
				like,
				ActionDate
			)
			VALUES (
				vr_application_id,
				vr_user_id,
				vr_likedID,
				vr_like,
				vr_now
			)
		END
	END
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS rv_get_fan_ids;

CREATE PROCEDURE rv_get_fan_ids
	vr_application_id		UUID,
	vr_likedID			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT l.user_id AS id
	FROM rv_likes AS l
	WHERE l.application_id =  vr_application_id AND l.liked_id = vr_likedID
END;


DROP PROCEDURE IF EXISTS rv_follow_unfollow;

CREATE PROCEDURE rv_follow_unfollow
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_followed_id			UUID,
	vr_follow			 BOOLEAN,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF COALESCE(vr_follow, 0) = 0 BEGIN
		DELETE rv_followers
		WHERE ApplicationID = vr_application_id AND FollowedID = vr_followed_id AND UserID = vr_user_id
	END
	ELSE BEGIN
		UPDATE rv_followers
			SET ActionDate = COALESCE(ActionDate, vr_now)
		WHERE ApplicationID = vr_application_id AND 
			FollowedID = vr_followed_id AND UserID = vr_user_id
			
		IF @vr_rowcount = 0 BEGIN
			INSERT INTO rv_followers (
				ApplicationID,
				UserID,
				FollowedID,
				ActionDate
			)
			VALUES (
				vr_application_id,
				vr_user_id,
				vr_followed_id,
				vr_now
			)
		END
	END
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS rv_set_system_settings;

CREATE PROCEDURE rv_set_system_settings
	vr_application_id	UUID,
	vr_itemsTemp		StringPairTableType readonly,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_items StringPairTableType
	INSERT INTO vr_items SELECT * FROM vr_itemsTemp
	
	UPDATE S
		SET Value = i.second_value,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_items AS i
		INNER JOIN rv_system_settings AS s
		ON s.application_id = vr_application_id AND s.name = i.first_value
		
	INSERT INTO rv_system_settings (ApplicationID, Name, Value, 
		LastModifierUserID, LastModificationDate)
	SELECT vr_application_id, i.first_value, gfn_verify_string(i.second_value), vr_current_user_id, vr_now
	FROM vr_items AS i
		LEFT JOIN rv_system_settings AS s
		ON s.application_id = vr_application_id AND s.name = i.first_value
	WHERE s.id IS NULL
	
	SELECT 1
END;


DROP PROCEDURE IF EXISTS rv_get_system_settings;

CREATE PROCEDURE rv_get_system_settings
	vr_application_id	UUID,
	vr_str_itemNames	varchar(2000),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_names StringTableType
	
	INSERT INTO vr_names (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_string_table(vr_str_itemNames, vr_delimiter) AS ref
	
	DECLARE vr_count INTEGER = (SELECT COUNT(*) FROM vr_names)
	
	SELECT s.name, s.value
	FROM rv_system_settings AS s
	WHERE s.application_id = vr_application_id AND 
		(vr_count = 0 OR s.name IN (SELECT n.value FROM vr_names AS n))
END;


DROP PROCEDURE IF EXISTS rv_get_last_content_creators;

CREATE PROCEDURE rv_get_last_content_creators
	vr_application_id		UUID,
	vr_count			 INTEGER
WITH ENCRYPTION
AS
BEGIN
	WITH Users
 AS 
	(
		SELECT	x.user_id, 
				MAX(x.date) AS date,
				N'Post' AS type
		FROM (
				SELECT TOP(20) ps.sender_user_id AS user_id, ps.send_date AS date
				FROM sh_post_shares AS ps
				WHERE ps.application_id = vr_application_id AND ps.deleted = FALSE
				ORDER BY ps.send_date DESC
			) AS x
		GROUP BY x.user_id

		UNION ALL

		SELECT	x.user_id, 
				MAX(x.date) AS date,
				N'Question' AS type
		FROM (
				SELECT TOP(20) q.sender_user_id AS user_id, q.send_date AS date
				FROM qa_questions AS q
				WHERE q.application_id = vr_application_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
				ORDER BY q.send_date DESC
			) AS x
		GROUP BY x.user_id

		UNION ALL

		SELECT	x.user_id, 
				MAX(x.date) AS date,
				N'Node' AS type
		FROM (
				SELECT TOP(20) nd.creator_user_id AS user_id, nd.creation_date AS date
				FROM cn_nodes AS nd
				WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE
				ORDER BY nd.creation_date DESC
			) AS x
		GROUP BY x.user_id

		UNION ALL

		SELECT	x.user_id, 
				MAX(x.date) AS date,
				N'Wiki' AS type
		FROM (
				SELECT TOP(20) c.user_id AS user_id, c.send_date  AS date
				FROM wk_changes AS c
				WHERE c.application_id = vr_application_id AND c.applied = 1
				ORDER BY c.send_date DESC
			) AS x
		GROUP BY x.user_id
	)
	SELECT TOP(COALESCE(vr_count, 10))
		x.user_id,
		un.username,
		un.first_name,
		un.last_name,
		x.date,
		x.types
	FROM (
			SELECT	users.user_id, 
					MAX(users.date) AS date,
					STUFF((
						SELECT ',' + type
						FROM Users AS x
						WHERE UserID = users.user_id
						FOR XML PATH(''),TYPE).value('(./text())1','VARCHAR(MAX)')
					  ,1,1,'') AS types
			FROM Users
			GROUP BY users.user_id
		) AS x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.user_id
	ORDER BY x.date DESC
END;


DROP PROCEDURE IF EXISTS rv_raai_van_statistics;

CREATE PROCEDURE rv_raai_van_statistics
	vr_application_id	UUID,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		(
			SELECT COUNT(NodeID)
			FROM cn_view_nodes_normal
			WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
				(vr_date_from IS NULL OR CreationDate >= vr_date_from) AND
				(vr_date_to IS NULL OR CreationDate <= vr_date_to)
		) AS nodes_count,
		(
			SELECT COUNT(QuestionID)
			FROM qa_questions
			WHERE ApplicationID = vr_application_id AND PublicationDate IS NOT NULL AND deleted = FALSE AND
				(vr_date_from IS NULL OR SendDate >= vr_date_from) AND
				(vr_date_to IS NULL OR SendDate <= vr_date_to)
		) AS questions_count,
		(
			SELECT COUNT(a.answer_id)
			FROM qa_answers AS a
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = a.question_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
			WHERE a.application_id = vr_application_id AND a.deleted = FALSE AND
				(vr_date_from IS NULL OR a.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR a.send_date <= vr_date_to)
		) AS answers_count,
		(
			SELECT COUNT(c.change_id)
			FROM wk_changes AS c
			WHERE c.application_id = vr_application_id AND c.applied = 1 AND c.deleted = FALSE AND
				(vr_date_from IS NULL OR c.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR c.send_date <= vr_date_to)
		) AS wiki_changes_count,
		(
			SELECT COUNT(ps.share_id)
			FROM sh_post_shares AS ps
			WHERE ps.application_id = vr_application_id AND ps.deleted = FALSE AND
				(vr_date_from IS NULL OR ps.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR ps.send_date <= vr_date_to)
		) AS posts_count,
		(
			SELECT COUNT(c.comment_id)
			FROM sh_comments AS c
			WHERE c.application_id = vr_application_id AND c.deleted = FALSE AND
				(vr_date_from IS NULL OR c.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR c.send_date <= vr_date_to)
		) AS comments_count,
		(
			SELECT COUNT(DISTINCT lg.user_id)
			FROM lg_logs AS lg
			WHERE lg.application_id = vr_application_id AND lg.action = N'Login' AND
				(vr_date_from IS NULL OR lg.date >= vr_date_from) AND
				(vr_date_to IS NULL OR lg.date <= vr_date_to)
		) AS active_users_count,
		(
			SELECT COUNT(ItemID) 
			FROM cn_nodes AS nd
				INNER JOIN usr_item_visits AS iv
				ON iv.application_id = vr_application_id AND iv.item_id = nd.node_id
			WHERE nd.application_id = vr_application_id AND nd.node_id = iv.item_id AND nd.deleted = FALSE AND
				(vr_date_from IS NULL OR iv.visit_date >= vr_date_from) AND
				(vr_date_to IS NULL OR iv.visit_date <= vr_date_to)
		) AS node_page_visits_count,
		(
			SELECT COUNT(LogID)
			FROM lg_logs AS lg
			WHERE lg.application_id = vr_application_id AND lg.action = N'Search' AND
				(vr_date_from IS NULL OR lg.date >= vr_date_from) AND
				(vr_date_to IS NULL OR lg.date <= vr_date_to)
		) AS searches_count
END;



DROP PROCEDURE IF EXISTS rv_schema_info;

CREATE PROCEDURE rv_schema_info
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	tbl.table_name AS table, 
			clm.column_name AS column, 
			CAST(CASE WHEN prm.column_name IS NULL THEN 0 ELSE 1 END AS boolean) AS is_primary_key,
			CAST(COLUMNPROPERTY(object_id(tbl.table_name), clm.column_name, 'IsIdentity') AS boolean) AS is_identity,
			CAST(CASE WHEN clm.is_nullable = 'YES' THEN 1 ELSE 0 END AS boolean) AS is_nullable, 
			UPPER(clm.data_type) AS data_type, 
			clm.character_maximum_length AS max_length,
			clm.ordinal_position AS order,
			clm.column_default AS default_value
	FROM information_schema.tables AS tbl
		INNER JOIN information_schema.columns AS clm
		ON clm.table_name = tbl.table_name
		LEFT JOIN (
			SELECT ccu.table_name, ccu.column_name
			FROM information_schema.table_constraints AS cnt
				INNER JOIN information_schema.constraint_column_usage AS ccu
				ON ccu.constraint_name = cnt.constraint_name
			WHERE cnt.constraint_type = N'PRIMARY KEY'
		) AS prm
		ON prm.table_name = tbl.table_name AND prm.column_name = clm.column_name
	WHERE tbl.table_type = N'BASE TABLE'
END;


DROP PROCEDURE IF EXISTS rv_foreign_keys;

CREATE PROCEDURE rv_foreign_keys
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	obj.name AS name,
			from_table.name AS table,
			from_column.name AS column,
			to_table.name AS ref_table,
			to_column.name AS ref_column
	FROM sys.foreign_key_columns AS fkc
		INNER JOIN sys.objects AS obj
		ON obj.object_id = fkc.constraint_object_id
		INNER JOIN sys.tables AS from_table
		ON from_table.object_id = fkc.parent_object_id
		INNER JOIN sys.columns AS from_column
		ON from_column.column_id = fkc.parent_column_id AND from_column.object_id = from_table.object_id
		INNER JOIN sys.tables AS to_table
		ON to_table.object_id = fkc.referenced_object_id
		INNER JOIN sys.columns AS to_column
		ON to_column.column_id = fkc.referenced_column_id AND to_column.object_id = to_table.object_id
END;


DROP PROCEDURE IF EXISTS rv_indexes;

CREATE PROCEDURE rv_indexes
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	ind.name AS name, 
			OBJECT_NAME(ind.object_id) AS table,
			COL_NAME(col.object_id, col.column_id) AS column,
			CAST(col.key_ordinal AS integer) AS order,
			col.is_descending_key AS is_descending,
			is_unique AS is_unique,
			is_unique_constraint AS is_unique_constraint,
			col.is_included_column AS is_included_column,
			type_desc AS index_type
	FROM sys.indexes AS ind
		INNER JOIN sys.index_columns AS col
		ON col.object_id = ind.object_id AND col.index_id = ind.index_id
	WHERE OBJECT_SCHEMA_NAME(ind.object_id) = 'dbo' AND ind.is_primary_key = 0 AND 
		ind.type_desc <> 'HEAP' AND OBJECTPROPERTY(ind.object_id, 'IsTable') = 1
	ORDER BY OBJECT_NAME(ind.object_id)
END;


DROP PROCEDURE IF EXISTS rv_user_defined_table_types;

CREATE PROCEDURE rv_user_defined_table_types
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	tp.name AS name,
			col.name AS column,
			CAST(col.column_id AS integer) AS order,
			st.name AS data_type,
			CAST(col.is_nullable AS boolean) AS is_nullable,
			CAST(col.is_identity AS boolean) AS is_identity,
			CAST(col.max_length AS integer) AS max_length
	FROM sys.table_types AS tp
		INNER JOIN sys.columns AS col
		ON tp.type_table_object_id = col.object_id
		INNER JOIN sys.systypes AS st  
		ON st.xtype = col.system_type_id
	where tp.is_user_defined = 1 AND st.name <> 'sysname'
	ORDER BY tp.name, col.column_id
END;


DROP PROCEDURE IF EXISTS rv_full_text_indexes;

CREATE PROCEDURE rv_full_text_indexes
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	OBJECT_NAME(ind.object_id) AS table, 
			c.name AS column,
			t.name AS data_type,
			CAST(c.max_length AS integer) AS max_length,
			CAST(c.is_identity AS boolean) AS is_identity
	FROM sys.fulltext_indexes AS ind
		INNER JOIN sys.fulltext_index_columns AS col
		ON col.object_id = ind.object_id
		INNER JOIN sys.columns AS c
		ON c.object_id = col.object_id AND c.column_id = col.column_id
		INNER JOIN sys.types AS t
		ON c.system_type_id = t.system_type_id
END;


DROP PROCEDURE IF EXISTS ntfn_send_notification;

CREATE PROCEDURE ntfn_send_notification
	vr_application_id	UUID,
    vr_usersTemp		GuidStringTableType readonly,
    vr_subjectID 		UUID,
    vr_ref_item_id 		UUID,
    vr_subjectType	varchar(20),
    vr_subjectName VARCHAR(2000),
    vr_action			varchar(20),
    vr_senderUserID 	UUID,
    vr_sendDate	 TIMESTAMP,
    vr_description VARCHAR(2000),
    vr_info		 VARCHAR(2000)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_users GuidStringTableType
	INSERT INTO vr_users SELECT * FROM vr_usersTemp
	
	DECLARE vr_vu GuidStringTableType
	INSERT INTO vr_vu(FirstValue, SecondValue)
	SELECT ref.first_value, ref.second_value
	FROM vr_users AS ref
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ref.first_value

	INSERT INTO ntfn_notifications(
		ApplicationID,
		UserID,
		SubjectID,
		RefItemID,
		SubjectType,
		SubjectName,
		action,
		SenderUserID,
		SendDate,
		description,
		Info,
		UserStatus,
		Seen,
		Deleted
	)
	SELECT vr_application_id, ref.first_value, vr_subjectID, vr_ref_item_id, vr_subjectType, 
		vr_subjectName, vr_action, vr_senderUserID, vr_sendDate, vr_description, 
		vr_info, ref.second_value, 0, 0
	FROM vr_vu AS ref
	WHERE ref.first_value <> vr_senderUserID AND 
		NOT EXISTS(
			SELECT TOP(1) * 
			FROM ntfn_notifications
			WHERE ApplicationID = vr_application_id AND UserID = ref.first_value AND 
				SubjectID = vr_subjectID AND RefItemID = vr_ref_item_id AND 
				action = vr_action AND SenderUserID = vr_senderUserID AND deleted = FALSE
		)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_set_notifications_as_seen;

CREATE PROCEDURE ntfn_set_notifications_as_seen
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_strIDs			varchar(max),
    vr_delimiter		char,
    vr_view_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs BigIntTableType
	INSERT INTO vr_iDs
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_big_int_table(vr_strIDs, vr_delimiter) AS ref
	
	UPDATE N
		SET Seen = 1,
			ViewDate = vr_view_date
	FROM vr_iDs AS ref
		INNER JOIN ntfn_notifications AS n
		ON n.id = ref.value
	WHERE n.application_id = vr_application_id AND n.user_id = vr_user_id AND n.seen = 0
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_set_user_notifications_as_seen;

CREATE PROCEDURE ntfn_set_user_notifications_as_seen
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_view_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE ntfn_notifications
		SET Seen = 1,
			ViewDate = vr_view_date
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id AND Seen = 0
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_arithmetic_delete_notification;

CREATE PROCEDURE ntfn_arithmetic_delete_notification
	vr_application_id	UUID,
    vr_iD				bigint,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE ntfn_notifications
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND ID = vr_iD AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_arithmetic_delete_notifications;

CREATE PROCEDURE ntfn_arithmetic_delete_notifications
	vr_application_id	UUID,
    vr_strSubjectIDs	varchar(max),
    vr_strRefItemIDs	varchar(max),
    vr_senderUserID	UUID,
    vr_strActions		varchar(max),
    vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_subjectIDs GuidTableType, vr_ref_item_ids GuidTableType
	
	INSERT INTO vr_subjectIDs
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strSubjectIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_ref_item_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strRefItemIDs, vr_delimiter) AS ref
	
	DECLARE vr_actions StringTableType
	INSERT INTO vr_actions
	SELECT ref.value FROM gfn_str_to_string_table(vr_strActions, vr_delimiter) AS ref
	
	DECLARE vr_actionsCount INTEGER = (SELECT COUNT(*) FROM vr_actions),
		vr_subjectIDsCount INTEGER = (SELECT COUNT(*) FROM vr_subjectIDs),
		vr_ref_item_idsCount INTEGER = (SELECT COUNT(*) FROM vr_ref_item_ids)
	
	IF vr_subjectIDsCount > 0 AND vr_ref_item_idsCount > 0 BEGIN
		UPDATE N
			SET deleted = TRUE
		FROM vr_subjectIDs AS s
			INNER JOIN ntfn_notifications AS n
			ON n.subject_id = s.value
			INNER JOIN vr_ref_item_ids AS r
			ON r.value = n.ref_item_id
		WHERE n.application_id = vr_application_id AND
			(vr_senderUserID IS NULL OR SenderUserID = vr_senderUserID) AND
			(vr_actionsCount = 0 OR action IN(SELECT * FROM vr_actions))
	END
	ELSE IF vr_subjectIDsCount > 0 BEGIN
		UPDATE N
			SET deleted = TRUE
		FROM vr_subjectIDs AS s
			INNER JOIN ntfn_notifications AS n
			ON n.subject_id = s.value
		WHERE n.application_id = vr_application_id AND 
			(vr_senderUserID IS NULL OR SenderUserID = vr_senderUserID) AND
			(vr_actionsCount = 0 OR action IN(SELECT * FROM vr_actions))
	END
	ELSE IF vr_ref_item_idsCount > 0 BEGIN
	select vr_senderUserID
		UPDATE N
			SET deleted = TRUE
		FROM vr_ref_item_ids AS r
			INNER JOIN ntfn_notifications AS n
			ON n.ref_item_id = r.value
		WHERE n.application_id = vr_application_id AND 
			(vr_senderUserID IS NULL OR n.sender_user_id = vr_senderUserID) AND
			(vr_actionsCount = 0 OR n.action IN(SELECT * FROM vr_actions))
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_get_user_notifications_count;

CREATE PROCEDURE ntfn_get_user_notifications_count
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_seen		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT COUNT(ID)
	FROM ntfn_notifications
	WHERE ApplicationID = vr_application_id AND 
		UserID = vr_user_id AND (vr_seen IS NULL OR Seen = vr_seen) AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS ntfn_p_get_notifications_by_ids;

CREATE PROCEDURE ntfn_p_get_notifications_by_ids
	vr_application_id	UUID,
    vr_iDsTemp		BigIntTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs BigIntTableType
	INSERT INTO vr_iDs SELECT * FROM vr_iDsTemp

	SELECT ntfn.id AS notification_id,
		   ntfn.user_id AS user_id,
		   ntfn.subject_id AS subject_id,
		   ntfn.ref_item_id AS ref_item_id,
		   ntfn.subject_name AS subject_name,
		   ntfn.subject_type AS subject_type,
		   ntfn.sender_user_id AS sender_user_id,
		   un.username AS sender_username,
		   un.first_name AS sender_first_name,
		   un.last_name AS sender_last_name,
		   ntfn.send_date AS send_date,
		   ntfn.action AS action,
		   ntfn.description AS description,
		   ntfn.info AS info,
		   ntfn.user_status AS user_status,
		   ntfn.seen AS seen,
		   ntfn.view_date AS view_date
	FROM vr_iDs AS ref
		INNER JOIN ntfn_notifications AS ntfn
		ON ntfn.application_id = vr_application_id AND ntfn.id = ref.value
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ntfn.user_id
	ORDER BY ntfn.seen ASC, ntfn.id DESC
END;


DROP PROCEDURE IF EXISTS ntfn_get_user_notifications;

CREATE PROCEDURE ntfn_get_user_notifications
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_seen		 BOOLEAN,
    vr_last_not_seen_id	bigint,
    vr_last_seen_id		bigint,
    vr_last_view_date TIMESTAMP,
    vr_lower_date_limit TIMESTAMP,
    vr_upper_date_limit TIMESTAMP,
    vr_count		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_iDs BigIntTableType
	
	INSERT INTO vr_iDs
	SELECT TOP(COALESCE(vr_count, 20)) ID
	FROM ntfn_notifications
	WHERE ApplicationID = vr_application_id AND UserID = vr_user_id AND
		(vr_lower_date_limit IS NULL OR SendDate > vr_lower_date_limit) AND
		(vr_upper_date_limit IS NULL OR SendDate < vr_upper_date_limit) AND
		(
			(
				(ViewDate IS NULL OR vr_last_view_date IS NULL) AND 
				(vr_last_not_seen_id IS NULL OR ID < vr_last_not_seen_id)
			) OR
			(
				(ViewDate < vr_last_view_date) AND 
				(vr_last_seen_id IS NULL OR ID < vr_last_seen_id)
			)
		) AND
		(vr_seen IS NULL OR Seen = vr_seen) AND deleted = FALSE
	ORDER BY Seen ASC, ID DESC
	
	EXEC ntfn_p_get_notifications_by_ids vr_application_id, vr_iDs
END;


-- Dashboard Procedures

DROP PROCEDURE IF EXISTS ntfn_p_send_dashboards;

CREATE PROCEDURE ntfn_p_send_dashboards
	vr_application_id	UUID,
    vr_dashboardsTemp	DashboardTableType readonly,
    vr__result	 INTEGER output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_dashboards DashboardTableType
	INSERT INTO vr_dashboards SELECT * FROM vr_dashboardsTemp
	
	INSERT INTO ntfn_dashboards(
		ApplicationID,
		UserID,
		NodeID,
		RefItemID,
		type,
		SubType,
		Info,
		Removable,
		SenderUserID,
		SendDate,
		ExpirationDate,
		Seen,
		ViewDate,
		Done,
		ActionDate,
		Deleted
	)
	SELECT DISTINCT
		vr_application_id,
		ref.user_id,
		ref.node_id,
		COALESCE(ref.ref_item_id, ref.node_id),
		ref.type,
		ref.subtype,
		ref.info,
		COALESCE(ref.removable, 0),
		ref.sender_user_id,
		ref.send_date,
		ref.expiration_date,
		COALESCE(ref.seen, 0),
		ref.view_date,
		COALESCE(ref.done, FALSE),
		ref.action_date,
		0
	FROM vr_dashboards AS ref
		LEFT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND 
			d.user_id = ref.user_id AND d.node_id = ref.node_id AND 
			d.ref_item_id = ref.ref_item_id AND d.type = ref.type AND 
			((d.subtype IS NULL AND ref.subtype IS NULL) OR d.subtype = ref.subtype) AND
			ref.removable = d.removable AND d.done = FALSE AND d.deleted = FALSE
	WHERE d.id IS NULL
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS ntfn_set_dashboards_as_seen;

CREATE PROCEDURE ntfn_set_dashboards_as_seen
	vr_application_id		UUID,
	vr_user_id				UUID,
    vr_strDashboardIDs	varchar(max),
    vr_delimiter			char,
    vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_dashboard_ids BigIntTableType
	
	INSERT INTO vr_dashboard_ids
	SELECT ref.value
	FROM gfn_str_to_big_int_table(vr_strDashboardIDs, vr_delimiter) AS ref
	
	UPDATE D
		SET Seen = 1,
			ViewDate = vr_now
	FROM vr_dashboard_ids AS ref
		INNER JOIN ntfn_dashboards AS d
		ON d.id = ref.value
	WHERE d.application_id = vr_application_id AND d.user_id = vr_user_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_p_set_dashboards_as_not_seen;

CREATE PROCEDURE ntfn_p_set_dashboards_as_not_seen
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_node_id			UUID,
    vr_ref_item_id		UUID,
    vr_type			varchar(20),
    vr_subType		varchar(20),
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM ntfn_dashboards
		WHERE ApplicationID = vr_application_id AND
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
			(vr_type IS NULL OR type = vr_type) AND
			(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
		) BEGIN
		UPDATE ntfn_dashboards
			SET Seen = 0
		WHERE ApplicationID = vr_application_id AND 
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
			(vr_type IS NULL OR type = vr_type) AND
			(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
			
		SET vr__result = @vr_rowcount
	END
	ELSE BEGIN
		SET vr__result = 1
	END
END;


DROP PROCEDURE IF EXISTS ntfn_p_set_dashboards_as_done;

CREATE PROCEDURE ntfn_p_set_dashboards_as_done
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_node_id			UUID,
    vr_ref_item_id		UUID,
    vr_type			varchar(20),
    vr_subType		varchar(20),
    vr_now		 TIMESTAMP,
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM ntfn_dashboards
		WHERE ApplicationID = vr_application_id AND 
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
			(vr_type IS NULL OR type = vr_type) AND
			(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
		) BEGIN
		
		UPDATE ntfn_dashboards
			SET done = TRUE,
				ActionDate = vr_now
		WHERE ApplicationID = vr_application_id AND 
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
			(vr_type IS NULL OR type = vr_type) AND
			(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
			
		SET vr__result = @vr_rowcount
	END
	ELSE BEGIN
		SET vr__result = 1
	END
END;


DROP PROCEDURE IF EXISTS ntfn_p_arithmetic_delete_dashboards;

CREATE PROCEDURE ntfn_p_arithmetic_delete_dashboards
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_node_id			UUID,
    vr_ref_item_id		UUID,
    vr_type			varchar(20),
    vr_subType		varchar(20),
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM ntfn_dashboards
		WHERE ApplicationID = vr_application_id AND
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
			(vr_type IS NULL OR type = vr_type) AND 
			(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
		) BEGIN
		
		UPDATE ntfn_dashboards
			SET deleted = TRUE
		WHERE ApplicationID = vr_application_id AND 
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
			(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
			
		SET vr__result = @vr_rowcount
	END
	ELSE BEGIN
		SET vr__result = 1
	END
END;


DROP PROCEDURE IF EXISTS ntfn_arithmetic_delete_dashboards;

CREATE PROCEDURE ntfn_arithmetic_delete_dashboards
	vr_application_id		UUID,
	vr_user_id				UUID,
    vr_strDashboardIDs	varchar(max),
    vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_dashboard_ids BigIntTableType
	
	INSERT INTO vr_dashboard_ids
	SELECT ref.value
	FROM gfn_str_to_big_int_table(vr_strDashboardIDs, vr_delimiter) AS ref
	
	UPDATE D
		SET deleted = TRUE
	FROM vr_dashboard_ids AS ref
		INNER JOIN ntfn_dashboards AS d
		ON d.id = ref.value
	WHERE d.application_id = vr_application_id AND d.user_id = vr_user_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_get_dashboards_count;

CREATE PROCEDURE ntfn_get_dashboards_count
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_nodeTypeID			UUID,
	vr_node_id				UUID,
	vr_nodeAdditionalID	varchar(50),
	vr_type				varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_node_id IS NOT NULL SET vr_nodeTypeID = NULL
	IF vr_node_id IS NOT NULL OR vr_nodeAdditionalID = N'' SET vr_nodeAdditionalID = NULL

	DECLARE vr_results TABLE (SeenOrder INTEGER, ID bigint, UserID UUID, 
		NodeID UUID, NodeAdditionalID varchar(50), NodeName VARCHAR(255), 
		NodeTypeID UUID, NodeType VARCHAR(255), type varchar(50), SubType VARCHAR(500), 
		WFState VARCHAR(1000), Removable BOOLEAN, SenderUserID UUID, SendDate TIMESTAMP, 
		ExpirationDate TIMESTAMP, Seen BOOLEAN, ViewDate TIMESTAMP, Done BOOLEAN, ActionDate TIMESTAMP, 
		InWorkFlow BOOLEAN, DoneAndInWorkFlow INTEGER, DoneAndNotInWorkFlow INTEGER,
		PRIMARY KEY CLUSTERED(nodeid, type, id))


	INSERT INTO vr_results (SeenOrder, ID, UserID, NodeID, NodeAdditionalID, NodeName, 
		NodeTypeID, NodeType, type, SubType, WFState, Removable, SenderUserID, SendDate, 
		ExpirationDate, Seen, ViewDate, Done, ActionDate)
	SELECT
		CASE WHEN d.seen = 0 THEN 0 ELSE 1 END AS seen_order,
		d.id, 
		d.user_id, 
		d.node_id, 
		nd.node_additional_id, 
		COALESCE(nd.node_name, q.title) AS node_name,
		nd.node_type_id,
		nd.type_name AS node_type, 
		d.type, 
		d.subtype, 
		nd.wf_state, 
		d.removable,
		d.sender_user_id, 
		d.send_date, 
		d.expiration_date,
		d.seen, 
		d.view_date, 
		d.done, 
		d.action_date
	FROM ntfn_dashboards AS d
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_id = d.node_id AND nd.deleted = FALSE
		LEFT JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND 
			q.question_id = d.node_id AND q.deleted = FALSE
	WHERE d.application_id = vr_application_id AND d.deleted = FALSE AND
		(nd.node_id IS NOT NULL OR q.question_id IS NOT NULL) AND
		(vr_user_id IS NULL OR d.user_id = vr_user_id) AND 
		(vr_node_id IS NULL OR d.node_id = vr_node_id) AND
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
		(vr_nodeAdditionalID IS NULL OR nd.node_additional_id = vr_nodeAdditionalID) AND
		(vr_type IS NULL OR d.type = vr_type)
			
			
	-- Remove Invalid WorkFlow Items
	IF COALESCE(vr_type, N'') = N'' OR vr_type = N'WorkFlow' BEGIN
		DELETE R
		FROM vr_results AS r
			LEFT JOIN wf_workflow_owners AS wo
			ON wo.application_id = vr_application_id AND wo.node_type_id = r.node_type_id AND wo.deleted = FALSE
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = r.node_type_id
		WHERE r.node_type_id IS NOT NULL AND r.type = N'WorkFlow' AND 
			(wo.workflow_id IS NULL OR s.is_knowledge = TRUE)
	END
	-- end of Remove Invalid WorkFlow Items


	-- Remove Invalid Knowledge Items
	IF COALESCE(vr_type, N'') = N'' OR vr_type = N'Knowledge' BEGIN
		DELETE R
		FROM vr_results AS r
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = r.node_type_id
		WHERE r.node_type_id IS NOT NULL AND r.type = N'Knowledge' AND COALESCE(s.is_knowledge, FALSE) = 0
	END
	-- end of Remove Invalid Knowledge Items


	-- Remove Invalid Wiki Items
	IF COALESCE(vr_type, N'') = N'' OR vr_type = N'Wiki' BEGIN
		DELETE R
		FROM vr_results AS r
			LEFT JOIN cn_extensions AS s
			ON s.application_id = vr_application_id AND s.owner_id = r.node_type_id AND 
				s.extension = N'Wiki' AND s.deleted = FALSE
		WHERE r.node_type_id IS NOT NULL AND r.type = N'Wiki' AND s.owner_id IS NULL
	END
	-- end of Remove Invalid Wiki Items


	UPDATE R
		SET InWorkFlow = 1
	FROM vr_results AS r
		INNER JOIN (
			SELECT r.node_id, r.type
			FROM vr_results AS r
				INNER JOIN ntfn_dashboards AS d
				ON d.application_id = vr_application_id AND r.node_id IS NOT NULL AND r.type IN (N'WorkFlow', N'Knowledge') AND
					d.node_id = r.node_id AND d.type = r.type AND d.done = FALSE AND d.deleted = FALSE AND COALESCE(d.removable, 0) = 0
			GROUP BY r.node_id, r.type
		) AS x
		ON x.node_id = r.node_id AND x.type = r.type


	UPDATE X
		SET DoneAndInWorkFlow = a.done_and_in_workflow,
			DoneAndNotInWorkFlow = a.done_and_not_in_workflow
	FROM vr_results AS x
		INNER JOIN (
			SELECT u.user_id, u.type, u.node_type_id,
				COUNT(DISTINCT (CASE WHEN u.done_and_in_workflow = 1 THEN u.node_id ELSE NULL END)) AS done_and_in_workflow,
				COUNT(DISTINCT (CASE WHEN u.done_and_not_in_workflow = 1 THEN u.node_id ELSE NULL END)) AS done_and_not_in_workflow
			FROM (
					SELECT r.user_id, r.type, r.node_id, r.node_type_id, 
						CASE 
							WHEN MAX(CAST(COALESCE(r.done, FALSE) AS integer)) = 1 AND
								COALESCE(MAX(CAST(r.in_workflow AS integer)), 0) > 0 THEN 1
							ELSE 0
						END AS done_and_in_workflow,
						CASE 
							WHEN MAX(CAST(COALESCE(r.done, FALSE) AS integer)) = 1 AND
								COALESCE(MAX(CAST(r.in_workflow AS integer)), 0) = 0 THEN 1
							ELSE 0
						END AS done_and_not_in_workflow
					FROM vr_results AS r
					GROUP BY r.user_id, r.type, r.node_id, r.node_type_id
				) AS u
			GROUP BY u.user_id, u.type, u.node_type_id
		) AS a
		ON a.user_id = x.user_id AND a.type = x.type AND 
			((a.node_type_id IS NULL AND x.node_type_id IS NULL) OR (a.node_type_id = x.node_type_id))

	UPDATE vr_results
		SET SubType = WFState
	WHERE type = N'WorkFlow' 

	SELECT	r.type, 
			r.subtype, 
			r.node_type_id, 
			MAX(r.node_type) AS node_type,
			COALESCE(MAX(CASE WHEN COALESCE(r.done, FALSE) = 0 THEN r.send_date ELSE NULL END),
				MAX(CASE WHEN r.done = TRUE THEN r.send_date ELSE NULL END)) AS date_of_effect, -- تاریخ موثر
			COUNT(CASE WHEN COALESCE(r.done, FALSE) = 0 AND COALESCE(r.seen, 0) = 0 THEN r.node_id ELSE NULL END) AS not_seen, -- منتظر اقدام و دیده نشده
			COUNT(CASE WHEN COALESCE(r.done, FALSE) = 0 THEN r.node_id ELSE NULL END) AS to_be_done, -- منتظر اقدام
			COUNT(CASE WHEN r.done = TRUE THEN r.node_id ELSE NULL END) AS done, -- تعداد کل اقدامات انجام شده
			MAX(r.done_and_in_workflow) AS done_and_in_workflow, -- اقدام شده و از جریان خارج شده
			MAX(r.done_and_not_in_workflow) AS done_and_not_in_workflow -- اقدام شده و همچنان در جریان
	FROM vr_results AS r
	GROUP BY r.user_id, r.type, r.subtype, r.node_type_id
	ORDER BY DateOfEffect DESC
END;


DROP PROCEDURE IF EXISTS ntfn_p_get_dashboards_count;

CREATE PROCEDURE ntfn_p_get_dashboards_count
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_node_id			UUID,
    vr_ref_item_id		UUID,
    vr_type			varchar(20),
    vr_subType		varchar(20),
    vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr__result = COALESCE(
		(
			SELECT COUNT(ID)
			FROM ntfn_dashboards
			WHERE ApplicationID = vr_application_id AND
				(vr_user_id IS NULL OR UserID = vr_user_id) AND
				(vr_node_id IS NULL OR NodeID = vr_node_id) AND 
				(vr_ref_item_id IS NULL OR RefItemID = vr_ref_item_id) AND 
				(vr_type IS NULL OR type = vr_type) AND
				(vr_subType IS NULL OR SubType = vr_subType) AND done = FALSE AND deleted = FALSE
		), 0
	)
END;


DROP PROCEDURE IF EXISTS ntfn_get_dashboards;

CREATE PROCEDURE ntfn_get_dashboards
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_nodeTypeID			UUID,
	vr_node_id				UUID,
	vr_nodeAdditionalID	varchar(50),
	vr_type				varchar(50),
	vr_subType		 VARCHAR(500),
	vr_doneState		 BOOLEAN,
	vr_date_from		 TIMESTAMP,
	vr_date_to			 TIMESTAMP,
	vr_searchText		 VARCHAR(500),
	vr_get_distinct_items BOOLEAN,
	vr_inWorkFlowState BOOLEAN,
	vr_lower_boundary	 INTEGER,
	vr_count			 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_node_id IS NOT NULL SET vr_nodeTypeID = NULL
	IF vr_node_id IS NOT NULL OR vr_nodeAdditionalID = N'' SET vr_nodeAdditionalID = NULL

	DECLARE vr_results TABLE (SeenOrder INTEGER, ID bigint, UserID UUID, 
		NodeID UUID, NodeAdditionalID varchar(50), NodeName VARCHAR(255), 
		NodeTypeID UUID, NodeType VARCHAR(255), type varchar(50), 
		SubType VARCHAR(500), WFState VARCHAR(1000),
		Info VARCHAR(1000), Removable BOOLEAN, SenderUserID UUID, SendDate TIMESTAMP, 
		ExpirationDate TIMESTAMP, Seen BOOLEAN, ViewDate TIMESTAMP, Done BOOLEAN, ActionDate TIMESTAMP, 
		InWorkFlow BOOLEAN, DoneAndInWorkFlow INTEGER, DoneAndNotInWorkFlow INTEGER)


	INSERT INTO vr_results (SeenOrder, ID, UserID, NodeID, NodeAdditionalID, NodeName, 
		NodeTypeID, NodeType, type, SubType, WFState, Info, Removable, SenderUserID, SendDate, 
		ExpirationDate, Seen, ViewDate, Done, ActionDate)
	SELECT
		CASE WHEN d.seen = 0 THEN 0 ELSE 1 END AS seen_order,
		d.id, 
		d.user_id, 
		d.node_id, 
		nd.node_additional_id, 
		COALESCE(nd.node_name, q.title) AS node_name,
		nd.node_type_id,
		nd.type_name AS node_type, 
		d.type, 
		d.subtype, 
		nd.wf_state,
		d.info, 
		d.removable,
		d.sender_user_id, 
		d.send_date, 
		d.expiration_date,
		d.seen, 
		d.view_date, 
		d.done, 
		d.action_date
	FROM ntfn_dashboards AS d
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_id = d.node_id AND nd.deleted = FALSE
		LEFT JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND 
			q.question_id = d.node_id AND q.deleted = FALSE
	WHERE d.application_id = vr_application_id AND d.deleted = FALSE AND
		(nd.node_id IS NOT NULL OR q.question_id IS NOT NULL) AND
		(vr_user_id IS NULL OR d.user_id = vr_user_id) AND 
		(vr_node_id IS NULL OR d.node_id = vr_node_id) AND
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
		(vr_nodeAdditionalID IS NULL OR nd.node_additional_id = vr_nodeAdditionalID) AND
		(vr_type IS NULL OR d.type = vr_type)
			
			
	-- Remove Invalid WorkFlow Items
	IF COALESCE(vr_type, N'') = N'' OR vr_type = N'WorkFlow' BEGIN
		DELETE R
		FROM vr_results AS r
			LEFT JOIN wf_workflow_owners AS wo
			ON wo.application_id = vr_application_id AND wo.node_type_id = r.node_type_id AND wo.deleted = FALSE
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = r.node_type_id
		WHERE r.node_type_id IS NOT NULL AND r.type = N'WorkFlow' AND 
			(wo.workflow_id IS NULL OR s.is_knowledge = TRUE)
	END
	-- end of Remove Invalid WorkFlow Items


	-- Remove Invalid Knowledge Items
	IF COALESCE(vr_type, N'') = N'' OR vr_type = N'Knowledge' BEGIN
		DELETE R
		FROM vr_results AS r
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = r.node_type_id
		WHERE r.node_type_id IS NOT NULL AND r.type = N'Knowledge' AND COALESCE(s.is_knowledge, FALSE) = 0
	END
	-- end of Remove Invalid Knowledge Items


	-- Remove Invalid Wiki Items
	IF COALESCE(vr_type, N'') = N'' OR vr_type = N'Wiki' BEGIN
		DELETE R
		FROM vr_results AS r
			LEFT JOIN cn_extensions AS s
			ON s.application_id = vr_application_id AND s.owner_id = r.node_type_id AND 
				s.extension = N'Wiki' AND s.deleted = FALSE
		WHERE r.node_type_id IS NOT NULL AND r.type = N'Wiki' AND s.owner_id IS NULL
	END
	-- end of Remove Invalid Wiki Items
	
	
	IF COALESCE(vr_searchText, N'') <> N'' BEGIN
		IF vr_type = N'Wiki' OR vr_type = N'WorkFlow' OR vr_type = N'Knowledge' OR vr_type = N'MembershipRequest' BEGIN
			DELETE R
			FROM vr_results AS r
				LEFT JOIN CONTAINSTABLE(cn_nodes, (name), vr_searchText) AS srch
				ON srch.key = r.node_id
			WHERE srch.key IS NULL
		END
		ELSE IF vr_type = N'Question' BEGIN
			DELETE R
			FROM vr_results AS r
				LEFT JOIN CONTAINSTABLE(qa_questions, (title), vr_searchText) AS srch
				ON srch.key = r.node_id
			WHERE srch.key IS NULL
		END
	END
	

	IF COALESCE(vr_get_distinct_items, 0) = 1 BEGIN
		IF vr_inWorkFlowState IS NOT NULL BEGIN
			UPDATE R
				SET InWorkFlow = 1
			FROM vr_results AS r
				INNER JOIN ntfn_dashboards AS d
				ON d.application_id = vr_application_id AND 
					d.node_id = r.node_id AND d.type = r.type AND d.done = FALSE AND d.deleted = FALSE AND COALESCE(d.removable, 0) = 0
			WHERE r.node_id IS NOT NULL AND r.type IN (N'WorkFlow', N'Knowledge')
		END
		
		SELECT TOP(COALESCE(vr_count, 50))
			(x.row_number + x.rev_row_number - 1) AS total_count,
			x.node_id AS id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY ref.send_date DESC, ref.node_id DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY ref.send_date ASC, ref.node_id ASC) AS rev_row_number,
						ref.node_id
				FROM (
						SELECT	r.node_id, 
								MAX(r.send_date) AS send_date, 
								MAX(CAST(r.in_workflow AS integer)) AS in_workflow
						FROM vr_results AS r
						WHERE r.node_id IS NOT NULL AND r.done = TRUE
						GROUP BY r.node_id
					) AS ref
				WHERE vr_inWorkFlowState IS NULL OR
					(vr_inWorkFlowState = 0 AND COALESCE(ref.in_workflow, 0) = 0) OR
					(vr_inWorkFlowState = 1 AND COALESCE(ref.in_workflow, 0) = 1)
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END -- end of 'IF vr_inWorkFlowState IS NOT NULL BEGIN'
	ELSE BEGIN
		SELECT TOP(COALESCE(vr_count, 50)) 
			(x.row_number + x.rev_row_number - 1) AS total_count,
			x.*
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY r.seen_order ASC, r.send_date DESC, r.id DESC) AS row_number,
						ROW_NUMBER() OVER (ORDER BY r.seen_order DESC, r.send_date ASC, r.id ASC) AS rev_row_number,
						r.*
				FROM vr_results AS r
				WHERE (vr_doneState IS NULL OR COALESCE(r.done, FALSE) = vr_doneState) AND
					(vr_date_from IS NULL OR r.send_date >= vr_date_from) AND
					(vr_date_to IS NULL OR r.send_date < vr_date_to) AND
					(vr_subType IS NULL OR r.subtype = vr_subType OR r.wf_state = vr_subType)
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
	END
END;


DROP PROCEDURE IF EXISTS ntfn_p_dashboard_exists;

CREATE PROCEDURE ntfn_p_dashboard_exists
	vr_application_id		UUID,
    vr_user_id				UUID,
	vr_node_id				UUID,
	vr_dashboard_type		varchar(20),
	vr_subType			varchar(20),
	vr_seen			 BOOLEAN,
	vr_done			 BOOLEAN,
	vr_lower_date_limit	 TIMESTAMP,
	vr_upper_date_limit	 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr__result = -1
	
	SELECT vr__result = 1
	WHERE EXISTS (
		SELECT TOP(1) ID
		FROM ntfn_dashboards
		WHERE ApplicationID = vr_application_id AND 
			(vr_user_id IS NULL OR UserID = vr_user_id) AND
			(vr_node_id IS NULL OR NodeID = vr_node_id) AND
			(vr_dashboard_type IS NULL OR type = vr_dashboard_type) AND
			(vr_subType IS NULL OR SubType = vr_subType) AND
			(vr_seen IS NULL OR Seen = vr_seen) AND
			(vr_done IS NULL OR Done = vr_done) AND
			(vr_lower_date_limit IS NULL OR SendDate >= vr_lower_date_limit) AND
			(vr_upper_date_limit IS NULL OR SendDate <= vr_upper_date_limit) AND deleted = FALSE
	)
END;


DROP PROCEDURE IF EXISTS ntfn_dashboard_exists;

CREATE PROCEDURE ntfn_dashboard_exists
	vr_application_id		UUID,
    vr_user_id				UUID,
	vr_node_id				UUID,
	vr_dashboard_type		varchar(20),
	vr_subType			varchar(20),
	vr_seen			 BOOLEAN,
	vr_done			 BOOLEAN,
	vr_lower_date_limit	 TIMESTAMP,
	vr_upper_date_limit	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	
	EXEC ntfn_p_dashboard_exists vr_application_id, vr_user_id, vr_node_id, vr_dashboard_type, 
		vr_subType, vr_seen, vr_done, vr_lower_date_limit, vr_upper_date_limit, vr__result output
		
	SELECT vr__result
END;

-- end of Dashboard Procedures


-- Message Template Procedures

DROP PROCEDURE IF EXISTS ntfn_set_message_template;

CREATE PROCEDURE ntfn_set_message_template
	vr_application_id		UUID,
	vr_templateID			UUID,
	vr_owner_id			UUID,
	vr_bodyText		 VARCHAR(4000),
	vr_audienceType		varchar(20),
	vr_audienceRefOwnerID	UUID,
	vr_audienceNodeID		UUID,
	vr_audienceNodeAdmin BOOLEAN,
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM ntfn_message_templates 
		WHERE ApplicationID = vr_application_id AND TemplateID = vr_templateID
	) BEGIN
		UPDATE ntfn_message_templates
			SET	BodyText = gfn_verify_string(vr_bodyText),
				AudienceType = vr_audienceType,
				AudienceRefOwnerID = vr_audienceRefOwnerID,
				AudienceNodeID = vr_audienceNodeID,
				AudienceNodeAdmin = COALESCE(vr_audienceNodeAdmin, 0),
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND TemplateID = vr_templateID
	END
	ELSE BEGIN
		INSERT INTO ntfn_message_templates(
			ApplicationID,
			TemplateID,
			OwnerID,
			BodyText,
			AudienceType,
			AudienceRefOwnerID,
			AudienceNodeID,
			AudienceNodeAdmin,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_templateID,
			vr_owner_id,
			gfn_verify_string(vr_bodyText),
			vr_audienceType,
			vr_audienceRefOwnerID,
			vr_audienceNodeID,
			COALESCE(vr_audienceNodeAdmin, 0),
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_arithmetic_delete_message_template;

CREATE PROCEDURE ntfn_arithmetic_delete_message_template
	vr_application_id			UUID,
	vr_templateID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE ntfn_message_templates
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND TemplateID = vr_templateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_p_get_owner_message_templates;

CREATE PROCEDURE ntfn_p_get_owner_message_templates
	vr_application_id	UUID,
	vr_owner_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids SELECT * FROM vr_owner_idsTemp
	
	SELECT mt.template_id,
		   mt.owner_id,
		   mt.body_text,
		   mt.audience_type,
		   mt.audience_ref_owner_id,
		   mt.audience_node_id,
		   nd.node_name AS audience_node_name,
		   nd.node_type_id AS audience_node_type_id,
		   nd.type_name AS audience_node_type,
		   mt.audience_node_admin
	FROM vr_owner_ids AS ref
		INNER JOIN ntfn_message_templates AS mt
		ON mt.owner_id = ref.value
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = mt.audience_node_id
	WHERE mt.application_id = vr_application_id AND mt.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS ntfn_get_owner_message_templates;

CREATE PROCEDURE ntfn_get_owner_message_templates
	vr_application_id	UUID,
	vr_strOwnerIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strOwnerIDs, vr_delimiter) AS ref
	
	EXEC ntfn_p_get_owner_message_templates vr_application_id, vr_owner_ids
END;

-- end of Message Template Procedures


-- Notification Messages (EMail & SMS)

DROP PROCEDURE IF EXISTS ntfn_get_notification_messages_info;

CREATE PROCEDURE ntfn_get_notification_messages_info
	vr_application_id		UUID,
	vr_ref_app_id			UUID,
	vr_user_status_pair_temp GuidStringTableType readOnly,
    vr_subjectType		VARCHAR(50),
	vr_action				VARCHAR(50)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_status_pair GuidStringTableType
	INSERT INTO vr_user_status_pair SELECT * FROM vr_user_status_pair_temp

	SELECT	ust.first_value AS user_id, 
			mt.media,
			mt.lang,
			mt.subject,
			mt.text
	FROM vr_user_status_pair AS ust
		INNER JOIN ntfn_user_messaging_activation AS so
		ON so.application_id = vr_application_id AND so.user_id = ust.first_value
		RIGHT JOIN ntfn_notification_message_templates AS mt
		ON mt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND mt.user_status = ust.second_value AND 
			mt.action = so.action AND mt.subject_type = so.subject_type AND 
			mt.media = so.media AND mt.lang = so.lang
	WHERE mt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
		mt.action = vr_action AND mt.subject_type = vr_subjectType AND 
		mt.enable = 1 AND COALESCE(so.enable, 1) = 1 
END;


DROP PROCEDURE IF EXISTS ntfn_set_user_messaging_activation;

CREATE PROCEDURE ntfn_set_user_messaging_activation
	vr_application_id			UUID,
	vr_option_id				UUID,
	vr_user_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP,
	vr_subjectType			VARCHAR(50),
	vr_user_status				VARCHAR(50),
	vr_action					VARCHAR(50),
	vr_media					VARCHAR(50),
	vr_lang					VARCHAR(50),
	vr_enable				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF(EXISTS(
		SELECT * 
		FROM ntfn_user_messaging_activation
		WHERE ApplicationID = vr_application_id AND OptionID = vr_option_id
	))BEGIN
		UPDATE ntfn_user_messaging_activation
			SET LastModifierUserId = vr_last_modifier_user_id,
				LastModificationDate = vr_last_modification_date,
				enable = vr_enable
		WHERE ApplicationID = vr_application_id AND OptionID = vr_option_id
	END
	ELSE BEGIN
		INSERT INTO ntfn_user_messaging_activation(
			ApplicationID,
			OptionID,
			UserID,
			SubjectType,
			UserStatus,
			action,
			Media,
			lang,
			enable
		)
		VALUES(
			vr_application_id,
			vr_option_id,
			vr_user_id,
			vr_subjectType,
			vr_user_status,
			vr_action,
			vr_media,
			vr_lang,
			vr_enable
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_get_notification_message_templates_info;

CREATE PROCEDURE ntfn_get_notification_message_templates_info
	vr_application_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	template_id,
			subject_type,
			action,
			media,
			UserStatus,
			lang,
			subject,
			text,
			enable
	FROM ntfn_notification_message_templates
	WHERE ApplicationID = vr_application_id
END;


DROP PROCEDURE IF EXISTS ntfn_get_user_messaging_activation;

CREATE PROCEDURE ntfn_get_user_messaging_activation
	vr_application_id	UUID,
	vr_ref_app_id		UUID,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		uma.option_id,
		CASE
			WHEN uma.subject_type IS NULL THEN nmt.subject_type
			ELSE uma.subject_type
		END AS subject_type,
		uma.user_id,
		CASE
			WHEN uma.user_status IS NULL THEN nmt.user_status
			ELSE uma.user_status
		END AS user_status,
		CASE
			WHEN uma.action IS NULL THEN nmt.action
			ELSE uma.action
		END AS action,
		CASE
			WHEN uma.media IS NULL THEN nmt.media
			ELSE uma.media
		END AS media,
		CASE
			WHEN uma.lang IS NULL THEN nmt.lang
			ELSE uma.lang
		END AS lang,
		uma.enable,
		nmt.enable AS admin_enable
	FROM ntfn_user_messaging_activation AS uma
		FULL OUTER JOIN ntfn_notification_message_templates AS nmt
		ON uma.application_id = vr_application_id AND nmt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
			uma.user_id = vr_user_id AND nmt.action = uma.action AND 
			nmt.lang = uma.lang AND nmt.media = uma.media AND 
			nmt.subject_type = uma.subject_type AND nmt.user_status = uma.user_status
	WHERE uma.application_id = vr_application_id AND 
		nmt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
		uma.user_id IS NULL OR uma.user_id = vr_user_id
END;


DROP PROCEDURE IF EXISTS ntfn_set_admin_messaging_activation;

CREATE PROCEDURE ntfn_set_admin_messaging_activation
	vr_application_id			UUID,
	vr_templateID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP,
	vr_subjectType			VARCHAR(50),
	vr_action					VARCHAR(50),
	vr_media					VARCHAR(50),
	vr_user_status				VARCHAR(50),
	vr_lang					VARCHAR(50),
	vr_enable				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF(EXISTS(
		SELECT * 
		FROM ntfn_notification_message_templates
		WHERE ApplicationID = vr_application_id AND TemplateID = vr_templateID
	))BEGIN
		UPDATE ntfn_notification_message_templates
			SET LastModifierUserId = vr_last_modifier_user_id,
				LastModificationDate = vr_last_modification_date,
				enable = vr_enable
		WHERE ApplicationID = vr_application_id AND TemplateID = vr_templateID
	END
	ELSE BEGIN
		INSERT INTO ntfn_notification_message_templates(
			ApplicationID,
			TemplateID,
			SubjectType,
			action,
			Media,
			UserStatus,
			lang,
			enable
		)
		VALUES(
			vr_application_id,
			vr_templateID,
			vr_subjectType,
			vr_action,
			vr_media,
			vr_user_status,
			vr_lang,
			1
		)
	END
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS ntfn_set_notification_message_template_text;

CREATE PROCEDURE ntfn_set_notification_message_template_text
	vr_application_id			UUID,
	vr_templateID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP,
	vr_subject				NVARCHAR (512),
	vr_text					NVARCHAR (max)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE ntfn_notification_message_templates
		SET LastModifierUserId = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
			subject = vr_subject,
			text = vr_text
	WHERE ApplicationID = vr_application_id AND TemplateID = vr_templateID
	
	SELECT @vr_rowcount
END;

-- end of Notification Messages (EMail & SMS)

DROP PROCEDURE IF EXISTS cn_p_initialize_service;

CREATE PROCEDURE cn_p_initialize_service
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr__result	 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM cn_services 
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	) BEGIN
		UPDATE cn_services
			SET deleted = FALSE
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	END
	ELSE BEGIN
		DECLARE vr_seqNo INTEGER = 
			COALESCE((
				SELECT MAX(SequenceNumber) 
				FROM cn_services
				WHERE ApplicationID = vr_application_id
			), 0) + 1
		
		INSERT INTO cn_services(
			ApplicationID,
			NodeTypeID,
			EnableContribution,
			EditableForAdmin,
			SequenceNumber,
			EditableForCreator,
			EditableForOwners,
			EditableForExperts,
			EditableForMembers,
			EditSuggestion,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_nodeTypeID,
			0,
			1,
			vr_seqNo,
			1,
			1,
			1,
			0,
			1,
			0
		)
	END
	
	SET vr__result = @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_initialize_service;

CREATE PROCEDURE cn_initialize_service
	vr_application_id	UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER = 0
	
	EXEC cn_p_initialize_service vr_application_id, vr_nodeTypeID, vr__result output
	
	SELECT vr__result
END;


DROP PROCEDURE IF EXISTS cn_p_get_services_by_ids;

CREATE PROCEDURE cn_p_get_services_by_ids
	vr_application_id		UUID,
	vr_node_type_idsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids KeyLessGuidTableType
	INSERT INTO vr_node_type_ids (Value) SELECT Value FROM vr_node_type_idsTemp
	
	SELECT s.node_type_id,
		   nt.name AS node_type,
		   s.service_title,
		   s.service_description,
		   s.admin_type,
		   s.admin_node_id,
		   s.max_acceptable_admin_level,
		   s.limit_attached_files_to,
		   s.max_attached_file_size,
		   s.max_attached_files_count,
		   s.enable_contribution,
		   s.no_content,
		   s.is_document,
		   s.enable_previous_version_select,
		   s.is_knowledge,
		   s.is_tree,
		   s.unique_membership,
		   s.unique_admin_member,
		   s.disable_abstract_and_keywords,
		   s.disable_file_upload,
		   s.disable_related_nodes_select,
		   s.editable_for_admin,
		   s.editable_for_creator,
		   s.editable_for_owners,
		   s.editable_for_experts,
		   s.editable_for_members,
		   COALESCE(s.edit_suggestion, 1) AS edit_suggestion
	FROM vr_node_type_ids AS ref
		INNER JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = ref.value
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = s.node_type_id
	ORDER BY ref.sequence_number ASC
END;


DROP PROCEDURE IF EXISTS cn_get_services_by_ids;

CREATE PROCEDURE cn_get_services_by_ids
	vr_application_id	UUID,
	vr_strNodeTypeIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids KeyLessGuidTableType
	
	INSERT INTO vr_node_type_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	
	EXEC cn_p_get_services_by_ids vr_application_id, vr_node_type_ids
END;


DROP PROCEDURE IF EXISTS cn_get_services;

CREATE PROCEDURE cn_get_services
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_current_user_id	UUID,
	vr_isDocument	 BOOLEAN,
	vr_isKnowledge BOOLEAN,
	vr_check_privacy BOOLEAN,
	vr_now		 TIMESTAMP,
	vr_default_privacy varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_nodeTypeID IS NOT NULL BEGIN
		SET vr_nodeTypeID = COALESCE(
			(
				SELECT TOP(1) NodeTypeID 
				FROM cn_nodes 
				WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeID
			),
			vr_nodeTypeID
		)
	END
	
	DECLARE vr_temp_ids KeyLessGuidTableType
	
	INSERT INTO vr_temp_ids (Value)
	SELECT s.node_type_id
	FROM cn_services AS s
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND 
			nt.node_type_id = s.node_type_id AND COALESCE(nt.deleted, FALSE) = 0
	WHERE s.application_id = vr_application_id AND
		(vr_nodeTypeID IS NULL OR s.node_type_id = vr_nodeTypeID) AND
		(vr_isDocument IS NULL OR s.is_document = vr_isDocument) AND
		(vr_isKnowledge IS NULL OR s.is_knowledge = vr_isKnowledge) AND
		(vr_nodeTypeID IS NOT NULL OR (s.service_title IS NOT NULL AND s.service_title <> N'')) AND 
		s.deleted = FALSE
	ORDER BY nt.sequence_number ASC, nt.creation_date DESC
	
	DECLARE vr_iDs KeyLessGuidTableType
	
	IF vr_nodeTypeID IS NULL AND vr_check_privacy = 1 BEGIN
		DECLARE	vr_permission_types StringPairTableType
		
		INSERT INTO vr_permission_types (FirstValue, SecondValue)
		VALUES (N'Create', vr_default_privacy)

		INSERT INTO vr_iDs (Value)
		SELECT ref.id
		FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
			vr_temp_ids, N'NodeType', vr_now, vr_permission_types) AS ref
			INNER JOIN vr_temp_ids AS t
			ON t.value = ref.id
		ORDER BY t.sequence_number ASC
	END
	ELSE BEGIN
		INSERT INTO vr_iDs (Value)
		SELECT ref.value
		FROM vr_temp_ids AS ref
		WHERE (vr_nodeTypeID IS NULL OR ref.value = vr_nodeTypeID)
		ORDER BY ref.sequence_number ASC
	END
	
	EXEC cn_p_get_services_by_ids vr_application_id, vr_iDs
END;


DROP PROCEDURE IF EXISTS cn_set_service_title;

CREATE PROCEDURE cn_set_service_title
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_title		 VARCHAR(512)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET ServiceTitle = gfn_verify_string(vr_title)
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_set_service_description;

CREATE PROCEDURE cn_set_service_description
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_description VARCHAR(4000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET ServiceDescription = gfn_verify_string(vr_description)
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_set_service_success_message;

CREATE PROCEDURE cn_set_service_success_message
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_message	 VARCHAR(4000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET success_message = vr_message
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_get_service_success_message;

CREATE PROCEDURE cn_get_service_success_message
	vr_application_id	UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT SuccessMessage
	FROM cn_services
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
END;


DROP PROCEDURE IF EXISTS cn_set_service_admin_type;

CREATE PROCEDURE cn_set_service_admin_type
	vr_application_id			UUID,
	vr_nodeTypeID				UUID,
	vr_adminType				varchar(20),
	vr_adminNodeID			UUID,
	vr_strLimitNodeTypeIDs	varchar(max),
	vr_delimiter				char,
	vr_creator_user_id			UUID,
	vr_creation_date		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET AdminType = vr_adminType,
			AdminNodeID = COALESCE(vr_adminNodeID, AdminNodeID)
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE cn_admin_type_limits
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	DECLARE vr_node_type_ids GuidTableType
	
	INSERT INTO vr_node_type_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strLimitNodeTypeIDs, vr_delimiter) AS ref
	
	DECLARE vr_existingIDs GuidTableType
	
	INSERT INTO vr_existingIDs
	SELECT ref.value
	FROM vr_node_type_ids AS ref
		INNER JOIN cn_admin_type_limits AS atl
		ON atl.limit_node_type_id = ref.value
	WHERE atl.application_id = vr_application_id AND atl.node_type_id = vr_nodeTypeID
	
	DECLARE vr_exisintg_count INTEGER = (SELECT COUNT(*) FROM vr_existingIDs)
	
	IF vr_exisintg_count > 0 BEGIN
		UPDATE ATL
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		FROM vr_existingIDs AS ref
			INNER JOIN cn_admin_type_limits AS atl
			ON atl.limit_node_type_id = ref.value
		WHERE atl.application_id = vr_application_id AND atl.node_type_id = vr_nodeTypeID
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF (SELECT COUNT(*) FROM vr_node_type_ids) > vr_exisintg_count BEGIN
		INSERT INTO cn_admin_type_limits(
			ApplicationID,
			NodeTypeID,
			LimitNodeTypeID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT vr_application_id, vr_nodeTypeID, ref.value, vr_creator_user_id, vr_creation_date, 0
		FROM vr_node_type_ids AS ref
		WHERE ref.value NOT IN(SELECT e.value FROM vr_existingIDs AS e)
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS cn_get_admin_area_limits;

CREATE PROCEDURE cn_get_admin_area_limits
	vr_application_id		UUID,
    vr_node_idOrTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids KeyLessGuidTableType
	
	DECLARE vr_nodeTypeID UUID = (
		SELECT NodeTypeID 
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_node_idOrTypeID
	)
	
	IF vr_nodeTypeID IS NULL SET vr_nodeTypeID = vr_node_idOrTypeID
	
	INSERT INTO vr_node_type_ids (Value)
	SELECT LimitNodeTypeID
	FROM cn_admin_type_limits
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND deleted = FALSE
	
	EXEC cn_p_get_node_types_by_ids vr_application_id, vr_node_type_ids
END;


DROP PROCEDURE IF EXISTS cn_set_max_acceptable_admin_level;

CREATE PROCEDURE cn_set_max_acceptable_admin_level
	vr_application_id				UUID,
	vr_nodeTypeID					UUID,
	vr_max_acceptable_admin_level INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET MaxAcceptableAdminLevel = vr_max_acceptable_admin_level
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_set_contribution_limits;

CREATE PROCEDURE cn_set_contribution_limits
	vr_application_id			UUID,
	vr_nodeTypeID				UUID,
	vr_strLimitNodeTypeIDs	varchar(max),
	vr_delimiter				char,
	vr_creator_user_id			UUID,
	vr_creation_date		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE cn_contribution_limits
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	DECLARE vr_node_type_ids GuidTableType
	
	INSERT INTO vr_node_type_ids
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strLimitNodeTypeIDs, vr_delimiter) AS ref
	
	DECLARE vr_existingIDs GuidTableType
	
	INSERT INTO vr_existingIDs
	SELECT ref.value
	FROM vr_node_type_ids AS ref
		INNER JOIN cn_contribution_limits AS cl
		ON cl.limit_node_type_id = ref.value
	WHERE cl.application_id = vr_application_id AND cl.node_type_id = vr_nodeTypeID
	
	DECLARE vr_exisintg_count INTEGER = (SELECT COUNT(*) FROM vr_existingIDs)
	
	IF vr_exisintg_count > 0 BEGIN
		UPDATE CL
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		FROM vr_existingIDs AS ref
			INNER JOIN cn_contribution_limits AS cl
			ON cl.limit_node_type_id = ref.value
		WHERE cl.application_id = vr_application_id AND cl.node_type_id = vr_nodeTypeID
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF (SELECT COUNT(*) FROM vr_node_type_ids) > vr_exisintg_count BEGIN
		INSERT INTO cn_contribution_limits(
			ApplicationID,
			NodeTypeID,
			LimitNodeTypeID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT vr_application_id, vr_nodeTypeID, ref.value, vr_creator_user_id, vr_creation_date, 0
		FROM vr_node_type_ids AS ref
		WHERE ref.value NOT IN(SELECT e.value FROM vr_existingIDs AS e)
		
		IF @vr_rowcount <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS cn_get_contribution_limits;

CREATE PROCEDURE cn_get_contribution_limits
	vr_application_id		UUID,
    vr_node_idOrTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids KeyLessGuidTableType
	
	DECLARE vr_nodeTypeID UUID = (
		SELECT NodeTypeID 
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_node_idOrTypeID
	)
	
	IF vr_nodeTypeID IS NULL SET vr_nodeTypeID = vr_node_idOrTypeID
	
	INSERT INTO vr_node_type_ids (Value)
	SELECT LimitNodeTypeID
	FROM cn_contribution_limits
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND deleted = FALSE
	
	EXEC cn_p_get_node_types_by_ids vr_application_id, vr_node_type_ids
END;


DROP PROCEDURE IF EXISTS cn_enable_contribution;

CREATE PROCEDURE cn_enable_contribution
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_enable		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EnableContribution = vr_enable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_no_content_service;

CREATE PROCEDURE cn_no_content_service
	vr_application_id			UUID,
	vr_nodeTypeIDOrNodeID		UUID,
	vr_no_content			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_nodeTypeIDOrNodeID = COALESCE(
		(
			SELECT TOP(1) NodeTypeID 
			FROM cn_nodes 
			WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeIDOrNodeID
		), vr_nodeTypeIDOrNodeID
	)
	
	IF vr_no_content IS NULL BEGIN
		SELECT TOP(1) NoContent
		FROM cn_services
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
	END
	ELSE BEGIN
		UPDATE cn_services
			SET NoContent = vr_no_content
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_is_knowledge;

CREATE PROCEDURE cn_is_knowledge
	vr_application_id			UUID,
	vr_nodeTypeIDOrNodeID		UUID,
	vr_isKnowledge		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_nodeTypeIDOrNodeID = COALESCE(
		(
			SELECT TOP(1) NodeTypeID 
			FROM cn_nodes 
			WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeIDOrNodeID
		), vr_nodeTypeIDOrNodeID
	)
	
	IF vr_isKnowledge IS NULL BEGIN
		SELECT TOP(1) IsKnowledge
		FROM cn_services
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
	END
	ELSE BEGIN
		UPDATE cn_services
			SET IsKnowledge = vr_isKnowledge
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_is_document;

CREATE PROCEDURE cn_is_document
	vr_application_id			UUID,
	vr_nodeTypeIDOrNodeID		UUID,
	vr_isDocument			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_nodeTypeIDOrNodeID = COALESCE(
		(
			SELECT TOP(1) NodeTypeID 
			FROM cn_nodes 
			WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeIDOrNodeID
		), vr_nodeTypeIDOrNodeID
	)
	
	IF vr_isDocument IS NULL BEGIN
		SELECT TOP(1) IsDocument
		FROM cn_services
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
	END
	ELSE BEGIN
		UPDATE cn_services
			SET IsDocument = vr_isDocument
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_enable_previous_version_select;

CREATE PROCEDURE cn_enable_previous_version_select
	vr_application_id			UUID,
	vr_nodeTypeIDOrNodeID		UUID,
	vr_value				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_nodeTypeIDOrNodeID = COALESCE(
		(
			SELECT TOP(1) NodeTypeID 
			FROM cn_nodes 
			WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeIDOrNodeID
		), vr_nodeTypeIDOrNodeID
	)
	
	IF vr_value IS NULL BEGIN
		SELECT TOP(1) IsDocument
		FROM cn_services
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
	END
	ELSE BEGIN
		UPDATE cn_services
			SET EnablePreviousVersionSelect = vr_value
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_is_tree;

CREATE PROCEDURE cn_is_tree
	vr_application_id			UUID,
	vr_strNodeTypeOrNodeIDs	varchar(max),
	vr_delimiter				char,
	vr_isTree				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids TABLE (FirstValue UUID not null primary key clustered,
		SecondValue UUID)
	
	INSERT INTO vr_node_type_ids (FirstValue, SecondValue)
	SELECT DISTINCT COALESCE(nd.node_type_id, i_ds.value), nd.node_id
	FROM gfn_str_to_guid_table(vr_strNodeTypeOrNodeIDs, vr_delimiter) AS i_ds
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
	
	IF vr_isTree IS NULL BEGIN
		SELECT COALESCE(nt.second_value, nt.first_value) AS id
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.is_tree = 1
	END
	ELSE BEGIN
		UPDATE S
			SET IsTree = vr_isTree
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_has_unique_membership;

CREATE PROCEDURE cn_has_unique_membership
	vr_application_id			UUID,
	vr_strNodeTypeOrNodeIDs	varchar(max),
	vr_delimiter				char,
	vr_value				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids TABLE (FirstValue UUID not null primary key clustered,
		SecondValue UUID)
	
	INSERT INTO vr_node_type_ids (FirstValue, SecondValue)
	SELECT DISTINCT COALESCE(nd.node_type_id, i_ds.value), nd.node_id
	FROM gfn_str_to_guid_table(vr_strNodeTypeOrNodeIDs, vr_delimiter) AS i_ds
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
	
	IF vr_value IS NULL BEGIN
		SELECT COALESCE(nt.second_value, nt.first_value) AS id
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.unique_membership = TRUE
	END
	ELSE BEGIN
		UPDATE S
			SET UniqueMembership = vr_value
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_has_unique_admin_member;

CREATE PROCEDURE cn_has_unique_admin_member
	vr_application_id			UUID,
	vr_strNodeTypeOrNodeIDs	varchar(max),
	vr_delimiter				char,
	vr_value				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids TABLE (FirstValue UUID not null primary key clustered,
		SecondValue UUID)
	
	INSERT INTO vr_node_type_ids (FirstValue, SecondValue)
	SELECT DISTINCT COALESCE(nd.node_type_id, i_ds.value), nd.node_id
	FROM gfn_str_to_guid_table(vr_strNodeTypeOrNodeIDs, vr_delimiter) AS i_ds
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
	
	IF vr_value IS NULL BEGIN
		SELECT COALESCE(nt.second_value, nt.first_value) AS id
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.unique_admin_member = TRUE
	END
	ELSE BEGIN
		UPDATE S
			SET UniqueAdminMember = vr_value
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_abstract_and_keywords_disabled;

CREATE PROCEDURE cn_abstract_and_keywords_disabled
	vr_application_id			UUID,
	vr_strNodeTypeOrNodeIDs	varchar(max),
	vr_delimiter				char,
	vr_value				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids TABLE (FirstValue UUID not null primary key clustered,
		SecondValue UUID)
	
	INSERT INTO vr_node_type_ids (FirstValue, SecondValue)
	SELECT DISTINCT COALESCE(nd.node_type_id, i_ds.value), nd.node_id
	FROM gfn_str_to_guid_table(vr_strNodeTypeOrNodeIDs, vr_delimiter) AS i_ds
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
	
	IF vr_value IS NULL BEGIN
		SELECT COALESCE(nt.second_value, nt.first_value) AS id
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.disable_abstract_and_keywords = 1
	END
	ELSE BEGIN
		UPDATE S
			SET DisableAbstractAndKeywords = vr_value
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_file_upload_disabled;

CREATE PROCEDURE cn_file_upload_disabled
	vr_application_id			UUID,
	vr_strNodeTypeOrNodeIDs	varchar(max),
	vr_delimiter				char,
	vr_value				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids TABLE (FirstValue UUID not null primary key clustered,
		SecondValue UUID)
	
	INSERT INTO vr_node_type_ids (FirstValue, SecondValue)
	SELECT DISTINCT COALESCE(nd.node_type_id, i_ds.value), nd.node_id
	FROM gfn_str_to_guid_table(vr_strNodeTypeOrNodeIDs, vr_delimiter) AS i_ds
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
	
	IF vr_value IS NULL BEGIN
		SELECT COALESCE(nt.second_value, nt.first_value) AS id
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.disable_file_upload = 1
	END
	ELSE BEGIN
		UPDATE S
			SET DisableFileUpload = vr_value
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_related_nodes_select_disabled;

CREATE PROCEDURE cn_related_nodes_select_disabled
	vr_application_id			UUID,
	vr_strNodeTypeOrNodeIDs	varchar(max),
	vr_delimiter				char,
	vr_value				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_type_ids TABLE (FirstValue UUID not null primary key clustered,
		SecondValue UUID)
	
	INSERT INTO vr_node_type_ids (FirstValue, SecondValue)
	SELECT DISTINCT COALESCE(nd.node_type_id, i_ds.value), nd.node_id
	FROM gfn_str_to_guid_table(vr_strNodeTypeOrNodeIDs, vr_delimiter) AS i_ds
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i_ds.value
	
	IF vr_value IS NULL BEGIN
		SELECT COALESCE(nt.second_value, nt.first_value) AS id
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.disable_related_nodes_select = 1
	END
	ELSE BEGIN
		UPDATE S
			SET DisableRelatedNodesSelect = vr_value
		FROM vr_node_type_ids AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL
		
		SELECT @vr_rowcount
	END
END;


DROP PROCEDURE IF EXISTS cn_editable_for_admin;

CREATE PROCEDURE cn_editable_for_admin
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_editable	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EditableForAdmin = vr_editable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_editable_for_creator;

CREATE PROCEDURE cn_editable_for_creator
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_editable	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EditableForCreator = vr_editable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_editable_for_owners;

CREATE PROCEDURE cn_editable_for_owners
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_editable	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EditableForOwners = vr_editable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_editable_for_experts;

CREATE PROCEDURE cn_editable_for_experts
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_editable	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EditableForExperts = vr_editable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_editable_for_members;

CREATE PROCEDURE cn_editable_for_members
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_editable	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EditableForMembers = vr_editable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_edit_suggestion;

CREATE PROCEDURE cn_edit_suggestion
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_enable		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_services
		SET EditSuggestion = vr_enable
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_add_free_user;

CREATE PROCEDURE cn_add_free_user
	vr_application_id		UUID,
	vr_nodeTypeID			UUID,
	vr_user_id				UUID,
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM cn_free_users
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND UserID = vr_user_id
	) BEGIN	
		UPDATE cn_free_users
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND UserID = vr_user_id
	END
	ELSE BEGIN
		INSERT INTO cn_free_users(
			ApplicationID,
			NodeTypeID,
			UserID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_nodeTypeID,
			vr_user_id,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_arithmetic_delete_free_user;

CREATE PROCEDURE cn_arithmetic_delete_free_user
	vr_application_id			UUID,
	vr_nodeTypeID				UUID,
	vr_user_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_free_users
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_get_free_user_ids;

CREATE PROCEDURE cn_get_free_user_ids
	vr_application_id	UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT UserID AS id
	FROM cn_free_users
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_is_free_user;

CREATE PROCEDURE cn_is_free_user
	vr_application_id			UUID,
	vr_nodeTypeIDOrNodeID		UUID,
	vr_user_id					UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) NodeTypeID 
		FROM cn_node_types 
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeIDOrNodeID
	) BEGIN
		SELECT TOP(1) vr_nodeTypeIDOrNodeID = NodeTypeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND NodeID = vr_nodeTypeIDOrNodeID
	END
	
	SELECT 
		CASE 
			WHEN EXISTS(
				SELECT TOP(1) UserID
				FROM cn_free_users
				WHERE ApplicationID = vr_application_id AND 
					NodeTypeID = vr_nodeTypeIDOrNodeID AND UserID = vr_user_id AND deleted = FALSE
			) THEN 1
			ELSE 0
		END
END;


DROP PROCEDURE IF EXISTS cn_add_service_admin;

CREATE PROCEDURE cn_add_service_admin
	vr_application_id		UUID,
	vr_nodeTypeID			UUID,
	vr_user_id				UUID,
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM cn_service_admins
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND UserID = vr_user_id
	) BEGIN
		
		UPDATE cn_service_admins
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND UserID = vr_user_id
	END
	ELSE BEGIN
		INSERT INTO cn_service_admins(
			ApplicationID,
			NodeTypeID,
			UserID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_nodeTypeID,
			vr_user_id,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_arithmetic_delete_service_admin;

CREATE PROCEDURE cn_arithmetic_delete_service_admin
	vr_application_id			UUID,
	vr_nodeTypeID				UUID,
	vr_user_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_service_admins
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND UserID = vr_user_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_get_service_admin_ids;

CREATE PROCEDURE cn_get_service_admin_ids
	vr_application_id	UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT UserID AS id
	FROM cn_service_admins
	WHERE ApplicationID = vr_application_id AND 
		(vr_nodeTypeID IS NULL OR NodeTypeID = vr_nodeTypeID) AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS cn_is_service_admin;

CREATE PROCEDURE cn_is_service_admin
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char,
	vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs GuidTableType
	
	INSERT INTO vr_iDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
	
	SELECT i.value AS id
	FROM vr_iDs AS i
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i.value
		INNER JOIN cn_service_admins AS sa
		ON sa.application_id = vr_application_id AND 
			sa.node_type_id = COALESCE(nd.node_type_id, i.value) AND 
			sa.user_id = vr_user_id AND sa.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS cn_register_new_node;

CREATE PROCEDURE cn_register_new_node
	vr_application_id		UUID,
	vr_node_id				UUID,
    vr_nodeTypeID			UUID,
    vr_additionalID_Main VARCHAR(300),
    vr_additionalID	 VARCHAR(50),
    vr_parent_node_id		UUID,
    vr_document_tree_nodeID	UUID,
    vr_previous_version_id	UUID,
	vr_name			 VARCHAR(255),
	vr_description	 VARCHAR(max),
	vr_tags			 VARCHAR(max),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP,
	vr_contributors_temp	GuidFloatTableType readonly,
	vr_owner_id			UUID,
	vr_workflow_id			UUID,
	vr_adminAreaID		UUID,
	vr_formInstanceID		UUID,
	vr_wf_director_node_id	UUID,
	vr_wf_director_user_id	UUID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_contributors GuidFloatTableType
	INSERT INTO vr_contributors SELECT * FROM vr_contributors_temp
	
	DECLARE vr_searchable BOOLEAN = 1
	
	-- Set searchability 
	SELECT TOP(1) vr_searchable = (
		CASE
			WHEN COALESCE(s.is_knowledge, FALSE) = 0 OR 
				kt.searchable_after = N'Registration' THEN CAST(1 AS boolean)
			ELSE CAST(0 AS boolean)
		END
	)
	FROM cn_services AS s
		LEFT JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = s.node_type_id
	WHERE s.application_id = vr_application_id AND 
		s.node_type_id = vr_nodeTypeID AND s.is_knowledge = TRUE
	
	DECLARE vr__message varchar(1000)
	DECLARE vr__result INTEGER = -1
	
	EXEC cn_p_add_node vr_application_id, vr_node_id, vr_additionalID, vr_nodeTypeID, NULL, 
		vr_document_tree_nodeID, vr_previous_version_id, vr_name, vr_description, vr_tags, vr_searchable, 
		vr_creator_user_id, vr_creation_date, vr_parent_node_id, vr_owner_id, NULL,
		vr__result output, vr__message output
	
	IF vr__result <= 0 BEGIN
		SELECT vr__result, COALESCE(vr__message, N'NodeCreationFailed')
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE cn_nodes
		SET AdditionalID_Main = vr_additionalID_Main,
			AreaID = vr_adminAreaID
	WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	
	-- Hide Previous Version
	IF (vr_searchable = 1 AND vr_previous_version_id IS NOT NULL) BEGIN
		UPDATE cn_nodes
			SET searchable = FALSE
		WHERE ApplicationID = vr_application_id AND NodeID = vr_previous_version_id AND deleted = FALSE
	END
	-- end of Hide Previous Version
	
	IF vr_formInstanceID IS NOT NULL BEGIN
		UPDATE fg_form_instances
			SET OwnerID = vr_node_id,
			 is_temporary = FALSE
		WHERE ApplicationID = vr_application_id AND InstanceID = vr_formInstanceID
	END
	
	SET vr__message = NULL
	
	EXEC cn_p_set_node_creators vr_application_id, vr_node_id, vr_contributors, 
		N'Accepted', vr_creator_user_id, vr_creation_date, vr__result output 
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'ErrorInAddingNodeCreators'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_document_tree_nodeID IS NOT NULL BEGIN
		DECLARE vr_doc_ids GuidTableType
		
		INSERT INTO vr_doc_ids (Value) VALUES (vr_node_id)
		
		EXEC dct_p_add_tree_node_contents vr_application_id, vr_document_tree_nodeID, 
			vr_doc_ids, NULL, vr_creator_user_id, vr_creation_date, vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT -1, N'ErrorInAddingTreeNodeContents'
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE vr_form_id UUID = (
		SELECT TOP(1) fw.form_id
		FROM fg_form_owners AS fw
		WHERE fw.application_id = vr_application_id AND 
			fw.owner_id = vr_nodeTypeID AND fw.deleted = FALSE AND vr_formInstanceID IS NULL
	)
	
	IF vr_form_id IS NOT NULL BEGIN
		IF EXISTS(
			SELECT TOP(1) * 
			FROM cn_extensions 
			WHERE ApplicationID = vr_application_id AND 
				OwnerID = vr_nodeTypeID AND Extension = N'Form' AND deleted = FALSE
		) BEGIN	
			DECLARE vr_instanceID UUID = gen_random_uuid()
			
			DECLARE vr_instances FormInstanceTableType
			
			INSERT INTO vr_instances (InstanceID, FormID, OwnerID, DirectorID, admin)
			VALUES (vr_instanceID, vr_form_id, vr_node_id, NULL, NULL)
		
			EXEC fg_p_create_form_instance vr_application_id, vr_instances, vr_creator_user_id, vr_creation_date, vr__result output	
				
			IF vr__result <= 0 BEGIN
				SELECT -1, N'FormInstanceInitializationFailed'
				ROLLBACK TRANSACTION
				RETURN
			END
		END
		ELSE BEGIN
			DECLARE vr_formElements StringPairTableType
			
			INSERT INTO vr_formElements (FirstValue, SecondValue)
			SELECT Title, N''
			FROM fg_extended_form_elements
			WHERE ApplicationID = vr_application_id AND FormID = vr_form_id AND deleted = FALSE
			ORDER BY SequenceNumber
			
			EXEC wk_p_create_wiki vr_application_id, vr_node_id, vr_formElements, 1, 
				vr_creator_user_id, vr_creation_date, vr__result output 
				
			IF vr__result <= 0 BEGIN
				SELECT -1, N'WikiInitializationFailed'
				ROLLBACK TRANSACTION
				RETURN
			END
		END
	END
	
	IF vr_workflow_id IS NOT NULL BEGIN
		EXEC wf_p_start_new_workflow vr_application_id, vr_node_id, vr_workflow_id, vr_wf_director_node_id, 
			vr_wf_director_user_id, vr_creator_user_id, vr_creation_date, vr__result output, vr__message output
		
		IF vr__result <= 0 BEGIN
			SELECT -1, COALESCE(vr__message, N'WorkFlowInitializationFailed')
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	ELSE BEGIN
		SELECT 1
	END
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS cn_set_admin_area;

CREATE PROCEDURE cn_set_admin_area
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_areaID			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE cn_nodes
		SET AreaID = vr_areaID
	WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
	
	SELECT @vr_rowcount
END;

DROP PROCEDURE IF EXISTS wf_p_send_dashboards;

CREATE PROCEDURE wf_p_send_dashboards
	vr_application_id		UUID,
	vr_history_id			UUID,
	vr_node_id				UUID,
	vr_workflow_id			UUID,
	vr_stateID			UUID,
	vr_director_user_id		UUID,
	vr_director_node_id		UUID,
	vr_data_need_instance_id	UUID,
	vr_sendDate		 TIMESTAMP,
	vr__result		 INTEGER output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_only_send_data_need BOOLEAN = 0
	IF vr_data_need_instance_id IS NOT NULL BEGIN
		SET vr_only_send_data_need = 1
		
		IF vr_history_id IS NULL SET vr_history_id = (
			SELECT TOP(1) HistoryID
			FROM wf_state_data_need_instances
			WHERE ApplicationID = vr_application_id AND InstanceID = vr_data_need_instance_id
		)
		
		IF vr_workflow_id IS NULL OR vr_stateID IS NULL OR vr_node_id IS NULL BEGIN
			SELECT vr_workflow_id = WorkFlowID, vr_stateID = StateID, vr_node_id = OwnerID
			FROM wf_history
			WHERE ApplicationID = vr_application_id AND HistoryID = vr_history_id
		END
	END
	
	DECLARE vr_dashboards DashboardTableType
	
	DECLARE vr_workflow_name VARCHAR(1000) = (
		SELECT TOP(1) Name 
		FROM wf_workflows 
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
	)
	
	DECLARE vr_stateTitle VARCHAR(1000) = (
		SELECT TOP(1) Title 
		FROM wf_states 
		WHERE ApplicationID = vr_application_id AND StateID = vr_stateID
	)
	
	INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, Info, Removable, SendDate)
	SELECT	nm.user_id, 
			vr_node_id, 
			sdni.instance_id, 
			N'WorkFlow',
			wf_fn_get_dashboard_info(vr_workflow_name, vr_stateTitle, sdni.instance_id),
			0,
			vr_sendDate
	FROM wf_state_data_need_instances AS sdni
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = sdni.node_id AND nm.is_pending = FALSE
	WHERE sdni.application_id = vr_application_id AND (
			(vr_only_send_data_need = 1 AND sdni.instance_id = vr_data_need_instance_id) OR
			(vr_only_send_data_need = 0 AND sdni.history_id = vr_history_id)
		) AND
		(sdni.admin = FALSE OR sdni.admin = nm.is_admin) AND sdni.deleted = FALSE
	
	IF vr_only_send_data_need = 0 BEGIN
		DECLARE vr_info VARCHAR(max) = 
			wf_fn_get_dashboard_info(vr_workflow_name, vr_stateTitle, vr_data_need_instance_id)
	
		IF vr_director_user_id IS NOT NULL BEGIN
			INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, Info, Removable, SendDate)
			VALUES (vr_director_user_id, vr_node_id, vr_history_id, N'WorkFlow', vr_info, 0, vr_sendDate)
		END
	
		IF vr_director_node_id IS NOT NULL BEGIN
			DECLARE vr_isDirectorNodeAdmin BOOLEAN = (
				SELECT TOP(1) admin
				FROM wf_workflow_states
				WHERE ApplicationID = vr_application_id AND 
					WorkFlowID = vr_workflow_id AND StateID = vr_stateID AND deleted = FALSE
			)
		
			INSERT INTO vr_dashboards(UserID, NodeID, RefItemID, type, Info, Removable, SendDate)
			SELECT	nm.user_id, vr_node_id, vr_history_id, N'WorkFlow', vr_info, 
				CASE
					WHEN COALESCE(vr_isDirectorNodeAdmin, 0) = 0 OR nm.is_admin = TRUE THEN CAST(0 AS boolean)
					ELSE CAST(1 AS boolean)
				END,
				vr_sendDate
			FROM cn_view_node_members AS nm
			WHERE ApplicationID = vr_application_id AND NodeID = vr_director_node_id AND 
				nm.is_pending = FALSE AND
				NOT EXISTS(
					SELECT TOP(1) * 
					FROM vr_dashboards AS ref 
					WHERE ref.user_id = nm.user_id
				)
		END
		
		EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
			NULL, vr_node_id, NULL, N'WorkFlow', NULL, vr__result output
		
		IF vr__result <= 0 RETURN
	END  -- end of 'IF vr_only_send_data_need = 1 BEGIN'
	
	IF (SELECT COUNT(*) FROM vr_dashboards) = 0 BEGIN
		SET vr__result = -1
		RETURN
	END
	
	EXEC ntfn_p_send_dashboards vr_application_id, vr_dashboards, vr__result output
	
	IF vr__result <= 0 RETURN
	
	IF vr__result > 0 BEGIN
		SELECT * 
		FROM vr_dashboards
	END
END;


DROP PROCEDURE IF EXISTS wf_create_state;

CREATE PROCEDURE wf_create_state
	vr_application_id		UUID,
	vr_stateID			UUID,
	vr_title			 VARCHAR(255),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__ret_val INTEGER
	SET vr__ret_val = 0
	
	SET vr_title = gfn_verify_string(vr_title)
	
	INSERT INTO wf_states(
		ApplicationID,
		StateID,
		Title,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_stateID,
		vr_title,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_modify_state;

CREATE PROCEDURE wf_modify_state
	vr_application_id			UUID,
	vr_stateID				UUID,
	vr_title				 VARCHAR(255),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	
	UPDATE wf_states
		SET Title = vr_title,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND StateID = vr_stateID
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_state;

CREATE PROCEDURE wf_arithmetic_delete_state
	vr_application_id			UUID,
	vr_stateID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_states
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND StateID = vr_stateID
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_p_get_states_by_ids;

CREATE PROCEDURE wf_p_get_states_by_ids
	vr_application_id	UUID,
	vr_stateIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType
	INSERT INTO vr_stateIDs SELECT * FROM vr_stateIDsTemp
	
	SELECT st.state_id AS state_id,
		   st.title AS title
	FROM vr_stateIDs AS external_ids
		INNER JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = external_ids.value
END;


DROP PROCEDURE IF EXISTS wf_get_states_by_ids;

CREATE PROCEDURE wf_get_states_by_ids
	vr_application_id	UUID,
	vr_strStateIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType
	INSERT vr_stateIDs
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strStateIDs, vr_delimiter) AS ref
	
	EXEC wf_p_get_states_by_ids vr_application_id, vr_stateIDs
END;


DROP PROCEDURE IF EXISTS wf_get_states;

CREATE PROCEDURE wf_get_states
	vr_application_id	UUID,
	vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType
	
	IF vr_workflow_id IS NULL BEGIN
		INSERT INTO vr_stateIDs
		SELECT StateID
		FROM wf_states
		WHERE ApplicationID = vr_application_id AND deleted = FALSE
	END
	ELSE BEGIN
		INSERT INTO vr_stateIDs
		SELECT StateID
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND deleted = FALSE
	END
	
	EXEC wf_p_get_states_by_ids vr_application_id, vr_stateIDs
END;


DROP PROCEDURE IF EXISTS wf_create_workflow;

CREATE PROCEDURE wf_create_workflow
	vr_application_id		UUID,
    vr_workflow_id			UUID,
	vr_name			 VARCHAR(255),
	vr_description	 VARCHAR(2000),
	vr_creator_user_id		UUID,
	vr_creation_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr__ret_val INTEGER
	SET vr__ret_val = 0
	
	SET vr_name = gfn_verify_string(vr_name)
	SET vr_description = gfn_verify_string(vr_description)
	
	IF EXISTS (
		SELECT TOP(1) * 
		FROM wf_workflows
		WHERE ApplicationID = vr_application_id AND Name = vr_name AND deleted = TRUE
	) BEGIN
		UPDATE wf_workflows
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND Name = vr_name AND deleted = TRUE
			
		SET vr__ret_val = @vr_rowcount
	END
	
	IF EXISTS (
		SELECT TOP(1) * 
		FROM wf_workflows
		WHERE ApplicationID = vr_application_id AND Name = vr_name AND deleted = FALSE
	) BEGIN
		SET vr__ret_val = -1
	END
	ELSE BEGIN
		INSERT INTO wf_workflows(
			ApplicationID,
			WorkFlowID,
			Name,
			description,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_workflow_id,
			vr_name,
			vr_description,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
		
		SET vr__ret_val = @vr_rowcount
	END
	
	SELECT vr__ret_val
END;


DROP PROCEDURE IF EXISTS wf_modify_workflow;

CREATE PROCEDURE wf_modify_workflow
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_name				 VARCHAR(255),
	vr_description		 VARCHAR(2000),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_name = gfn_verify_string(vr_name)
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE wf_workflows
		SET Name = vr_name,
			description = vr_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_workflow;

CREATE PROCEDURE wf_arithmetic_delete_workflow
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflows
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_p_get_workflows_by_ids;

CREATE PROCEDURE wf_p_get_workflows_by_ids
	vr_application_id		UUID,
	vr_workflow_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids GuidTableType
	INSERT INTO vr_workflow_ids SELECT * FROM vr_workflow_idsTemp
	
	SELECT wf.workflow_id AS workflow_id,
		   wf.name AS name,
		   wf.description AS description
	FROM vr_workflow_ids AS external_ids
		INNER JOIN wf_workflows AS wf
		ON wf.application_id = vr_application_id AND wf.workflow_id = external_ids.value
	ORDER BY wf.creation_date DESC
END;

DROP PROCEDURE IF EXISTS wf_get_workflows_by_ids;

CREATE PROCEDURE wf_get_workflows_by_ids
	vr_application_id		UUID,
	vr_strWorkFlowIDs		varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids GuidTableType
	INSERT vr_workflow_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strWorkFlowIDs, vr_delimiter) AS ref
	
	EXEC wf_p_get_workflows_by_ids vr_application_id, vr_workflow_ids
END;


DROP PROCEDURE IF EXISTS wf_get_workflows;

CREATE PROCEDURE wf_get_workflows
	vr_application_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_workflow_ids GuidTableType
	
	INSERT INTO vr_workflow_ids
	SELECT WorkFlowID
	FROM wf_workflows
	WHERE ApplicationID = vr_application_id AND deleted = FALSE
	
	EXEC wf_p_get_workflows_by_ids vr_application_id, vr_workflow_ids
END;


DROP PROCEDURE IF EXISTS wf_add_workflow_state;

CREATE PROCEDURE wf_add_workflow_state
	vr_application_id	UUID,
	vr_iD				UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND 
			WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	) BEGIN
		UPDATE wf_workflow_states
			SET deleted = FALSE,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND 
			WorkFlowID = vr_workflow_id AND StateID = vr_stateID AND deleted = TRUE
	END
	ELSE BEGIN
		INSERT INTO wf_workflow_states(
			ApplicationID,
			ID,
			WorkFlowID,
			StateID,
			ResponseType,
			admin,
			DescriptionNeeded,
			HideOwnerName,
			FreeDataNeedRequests,
			EditPermission,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_iD,
			vr_workflow_id,
			vr_stateID,
			NULL,
			0,
			1,
			0,
			0,
			0,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_workflow_state;

CREATE PROCEDURE wf_arithmetic_delete_workflow_state
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND StateID = vr_stateID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_workflow_state_description;

CREATE PROCEDURE wf_set_workflow_state_description
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_description		 VARCHAR(2000),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE wf_workflow_states
		SET description = vr_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_workflow_state_tag;

CREATE PROCEDURE wf_set_workflow_state_tag
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID,
	vr_tag		 VARCHAR(450),
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_tag_id UUID
	
	DECLARE vr_tags StringTableType
	INSERT INTO vr_tags (Value) VALUES(vr_tag)
	
	EXEC cn_p_add_tags vr_application_id, 
		vr_tags, vr_creator_user_id, vr_creation_date, vr_tag_id output
	
	UPDATE wf_workflow_states
		SET TagID = vr_tag_id
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_remove_workflow_state_tag;

CREATE PROCEDURE wf_remove_workflow_state_tag
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET TagID = NULL
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_tags;

CREATE PROCEDURE wf_get_workflow_tags
	vr_application_id	UUID,
	vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT wfs.tag_id, tg.tag
	FROM wf_workflow_states AS wfs
		INNER JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = wfs.tag_id
	WHERE wfs.application_id = vr_application_id AND 
		wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_set_state_director;

CREATE PROCEDURE wf_set_state_director
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_response_type			varchar(20),
	vr_ref_state_id				UUID,
	vr_node_id					UUID,
	vr_admin				 BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET ResponseType = vr_response_type,
			RefStateID = vr_ref_state_id,
			NodeID = vr_node_id,
			admin = vr_admin,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_poll;

CREATE PROCEDURE wf_set_state_poll
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID,
	vr_poll_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET PollID = vr_poll_id,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_data_needs_type;

CREATE PROCEDURE wf_set_state_data_needs_type
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_data_needs_type			varchar(20),
	vr_ref_state_id				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_ref_state_id IS NULL BEGIN
		UPDATE wf_workflow_states
			SET DataNeedsType = vr_data_needs_type,
				LastModifierUserID = vr_last_modifier_user_id,
				LastModificationDate = vr_last_modification_date
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	END
	ELSE BEGIN
		UPDATE wf_workflow_states
			SET DataNeedsType = vr_data_needs_type,
				RefDataNeedsStateID = vr_ref_state_id,
				LastModifierUserID = vr_last_modifier_user_id,
				LastModificationDate = vr_last_modification_date
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_data_needs_description;

CREATE PROCEDURE wf_set_state_data_needs_description
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_description		 VARCHAR(2000),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE wf_workflow_states
		SET DataNeedsDescription = vr_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_description_needed;

CREATE PROCEDURE wf_set_state_description_needed
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_descriptionNeeded	 BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET DescriptionNeeded = vr_descriptionNeeded,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_hide_owner_name;

CREATE PROCEDURE wf_set_state_hide_owner_name
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_hide_owner_name		 BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET HideOwnerName = vr_hide_owner_name,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_edit_permission;

CREATE PROCEDURE wf_set_state_edit_permission
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_edit_permission		 BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET EditPermission = vr_edit_permission,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_free_data_need_requests;

CREATE PROCEDURE wf_set_free_data_need_requests
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_free_data_need_requests BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET FreeDataNeedRequests = vr_free_data_need_requests,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_data_need;

CREATE PROCEDURE wf_set_state_data_need
	vr_application_id	UUID,
	vr_iD				UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID,
	vr_nodeTypeID		UUID,
	vr_pre_node_type_id	UUID,
	vr_form_id			UUID,
	vr_description VARCHAR(2000),
	vr_multiple_select BOOLEAN,
	vr_admin		 BOOLEAN,
	vr_necessary	 BOOLEAN,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	IF vr_pre_node_type_id IS NOT NULL AND vr_pre_node_type_id <> vr_nodeTypeID BEGIN
		UPDATE wf_state_data_needs
			SET LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = TRUE
		WHERE ApplicationID = vr_application_id AND 
			WorkFlowID = vr_workflow_id AND StateID = vr_stateID AND NodeTypeID = vr_pre_node_type_id
	END
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM wf_state_data_needs
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			StateID = vr_stateID AND NodeTypeID = vr_nodeTypeID
	) BEGIN
		UPDATE wf_state_data_needs
			SET description = vr_description,
				MultipleSelect = vr_multiple_select,
				admin = vr_admin,
				Necessary = vr_necessary,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			StateID = vr_stateID AND NodeTypeID = vr_nodeTypeID
	END
	ELSE BEGIN
		INSERT INTO wf_state_data_needs(
			ApplicationID,
			ID,
			WorkFlowID,
			StateID,
			NodeTypeID,
			description,
			MultipleSelect,
			admin,
			Necessary,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_iD,
			vr_workflow_id,
			vr_stateID,
			vr_nodeTypeID,
			vr_description,
			vr_multiple_select,
			vr_admin,
			vr_necessary,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	DECLARE vr__result INTEGER = @vr_rowcount
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_form_id IS NOT NULL BEGIN
		EXEC fg_p_set_form_owner vr_application_id, vr_iD, vr_form_id, 
			vr_creator_user_id, vr_creation_date, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT vr__result
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_state_data_need;

CREATE PROCEDURE wf_arithmetic_delete_state_data_need
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_nodeTypeID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_state_data_needs
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND StateID = vr_stateID AND 
		NodeTypeID = vr_nodeTypeID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_rejection_settings;

CREATE PROCEDURE wf_set_rejection_settings
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_max_allowed_rejections INTEGER,
	vr_rejection_title		 VARCHAR(255),
	vr_rejection_ref_state_id	UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET MaxAllowedRejections = vr_max_allowed_rejections,
			RejectionTitle = vr_rejection_title,
			RejectionRefStateID = vr_rejection_ref_state_id,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_max_allowed_rejections;

CREATE PROCEDURE wf_set_max_allowed_rejections
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_max_allowed_rejections INTEGER,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_states
		SET MaxAllowedRejections = vr_max_allowed_rejections,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_get_rejections_count;

CREATE PROCEDURE wf_get_rejections_count
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(HistoryID)
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND 
		WorkFlowID = vr_workflow_id AND StateID = vr_stateID AND Rejected = 1 AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_add_state_connection;

CREATE PROCEDURE wf_add_state_connection
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_inStateID		UUID,
	vr_outStateID		UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_sequenceNumber INTEGER = (
		SELECT COALESCE(MAX(SequenceNumber), 0) 
		FROM wf_state_connections
		WHERE ApplicationID = vr_application_id AND 
			WorkFlowID = vr_workflow_id AND InStateID = vr_inStateID
	) + 1
	
	DECLARE vr_iD UUID = (
		SELECT TOP(1) ID
		FROM wf_state_connections
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			InStateID = vr_inStateID AND OutStateID = vr_outStateID AND deleted = TRUE
	)
	
	IF vr_iD IS NOT NULL BEGIN
		UPDATE wf_state_connections
			SET deleted = FALSE,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND ID = vr_iD
	END
	ELSE BEGIN
		SET vr_iD = gen_random_uuid()
	
		INSERT INTO wf_state_connections(
			ApplicationID,
			ID,
			WorkFlowID,
			InStateID,
			OutStateID,
			SequenceNumber,
			Label,
			AttachmentRequired,
			NodeRequired,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_iD,
			vr_workflow_id,
			vr_inStateID,
			vr_outStateID,
			vr_sequenceNumber,
			N'',
			0,
			0,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT vr_iD
END;


DROP PROCEDURE IF EXISTS wf_sort_state_connections;

CREATE PROCEDURE wf_sort_state_connections
	vr_application_id	UUID,
	vr_strIDs			varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs TABLE (SequenceNo INTEGER identity(1, 1) primary key, ID UUID)
	
	INSERT INTO vr_iDs (ID)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strIDs, vr_delimiter) AS ref
	
	DECLARE vr_workflow_id UUID, vr_stateID UUID
	
	SELECT vr_workflow_id = WorkFlowID, vr_stateID = InStateID
	FROM wf_state_connections
	WHERE ApplicationID = vr_application_id AND ID = (SELECT TOP (1) ref.id FROM vr_iDs AS ref)
	
	IF vr_workflow_id IS NULL OR vr_stateID IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO vr_iDs (ID)
	SELECT sc.id
	FROM vr_iDs AS ref
		RIGHT JOIN wf_state_connections AS sc
		ON sc.id = ref.id
	WHERE sc.application_id = vr_application_id AND 
		sc.workflow_id = vr_workflow_id AND sc.in_state_id = vr_stateID AND ref.id IS NULL
	ORDER BY sc.sequence_number
	
	UPDATE wf_state_connections
		SET SequenceNumber = ref.sequence_no
	FROM vr_iDs AS ref
		INNER JOIN wf_state_connections AS sc
		ON sc.id = ref.id
	WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND sc.in_state_id = vr_stateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_move_state_connection;

CREATE PROCEDURE wf_move_state_connection
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_inStateID		UUID,
	vr_outStateID		UUID,
	vr_move_down	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_sequenceNo INTEGER = (
		SELECT TOP(1) SequenceNumber
		FROM wf_state_connections
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			InStateID = vr_inStateID AND OutStateID = vr_outStateID
	)
		
	DECLARE vr_other_out_state_id UUID
	DECLARE vr_other_sequence_number INTEGER
	
	IF vr_move_down = 1 BEGIN
		SELECT TOP(1) vr_other_out_state_id = OutStateID, vr_other_sequence_number = SequenceNumber
		FROM wf_state_connections
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			InStateID = vr_inStateID AND SequenceNumber > vr_sequenceNo
		ORDER BY SequenceNumber
	END
	ELSE BEGIN
		SELECT TOP(1) vr_other_out_state_id = OutStateID, vr_other_sequence_number = SequenceNumber
		FROM wf_state_connections
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			InStateID = vr_inStateID AND SequenceNumber < vr_sequenceNo
		ORDER BY SequenceNumber DESC
	END
	
	IF vr_other_out_state_id IS NULL BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE wf_state_connections
		SET SequenceNumber = vr_other_sequence_number
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE wf_state_connections
		SET SequenceNumber = vr_sequenceNo
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_other_out_state_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_state_connection;

CREATE PROCEDURE wf_arithmetic_delete_state_connection
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_inStateID				UUID,
	vr_outStateID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_state_connections
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_connection_label;

CREATE PROCEDURE wf_set_state_connection_label
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_inStateID				UUID,
	vr_outStateID				UUID,
	vr_label				 VARCHAR(255),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_label = gfn_verify_string(vr_label)
	
	UPDATE wf_state_connections
		SET Label = vr_label,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_connection_attachment_status;

CREATE PROCEDURE wf_set_state_connection_attachment_status
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_inStateID				UUID,
	vr_outStateID				UUID,
	vr_attachmentRequired	 BOOLEAN,
	vr_attachmentTitle	 VARCHAR(255),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_attachmentTitle = gfn_verify_string(vr_attachmentTitle)
	
	IF vr_attachmentRequired IS NULL SET vr_attachmentRequired = 0
	
	UPDATE wf_state_connections
		SET AttachmentRequired = vr_attachmentRequired,
			AttachmentTitle = vr_attachmentTitle,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_connection_director;

CREATE PROCEDURE wf_set_state_connection_director
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_inStateID				UUID,
	vr_outStateID				UUID,
	vr_nodeRequired		 BOOLEAN,
	vr_nodeTypeID				UUID,
	vr_nodeTypeDescription VARCHAR(2000),
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_nodeRequired IS NULL SET vr_nodeRequired = 0
	
	UPDATE wf_state_connections
		SET NodeRequired = vr_nodeRequired,
			NodeTypeID = vr_nodeTypeID,
			NodeTypeDescription = vr_nodeTypeDescription,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_set_state_connection_form;

CREATE PROCEDURE wf_set_state_connection_form
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_inStateID		UUID,
	vr_outStateID		UUID,
	vr_form_id			UUID,
	vr_description VARCHAR(4000),
	vr_necessary	 BOOLEAN,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	IF vr_necessary IS NULL SET vr_necessary = 0
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM wf_state_connection_forms
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			InStateID = vr_inStateID AND OutStateID = vr_outStateID AND FormID = vr_form_id
	) BEGIN
		UPDATE wf_state_connection_forms
			SET description = vr_description,
				Necessary = vr_necessary,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date,
			 deleted = FALSE
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
			InStateID = vr_inStateID AND OutStateID = vr_outStateID AND FormID = vr_form_id
	END
	ELSE BEGIN
		INSERT INTO wf_state_connection_forms(
			ApplicationID,
			WorkFlowID,
			InStateID,
			OutStateID,
			FormID,
			description,
			Necessary,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_workflow_id,
			vr_inStateID,
			vr_outStateID,
			vr_form_id,
			vr_description,
			vr_necessary,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_state_connection_form;

CREATE PROCEDURE wf_arithmetic_delete_state_connection_form
	vr_application_id			UUID,
	vr_workflow_id				UUID,
	vr_inStateID				UUID,
	vr_outStateID				UUID,
	vr_form_id					UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_state_connection_forms
		SET LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date,
		 deleted = TRUE
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID AND FormID = vr_form_id AND deleted = FALSE
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_add_auto_message;

CREATE PROCEDURE wf_add_auto_message
	vr_application_id	UUID,
	vr_autoMessageID	UUID,
	vr_owner_id		UUID,
	vr_bodyText	 VARCHAR(4000),
	vr_audienceType	varchar(20),
	vr_ref_state_id		UUID,
	vr_node_id			UUID,
	vr_admin		 BOOLEAN,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_bodyText = gfn_verify_string(vr_bodyText)
	
	IF vr_admin IS NULL SET vr_admin = 0
	
	INSERT INTO wf_auto_messages(
		ApplicationID,
		AutoMessageID,
		OwnerID,
		BodyText,
		AudienceType,
		RefStateID,
		NodeID,
		admin,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_autoMessageID,
		vr_owner_id,
		vr_bodyText,
		vr_audienceType,
		vr_ref_state_id,
		vr_node_id,
		vr_admin,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_modify_auto_message;

CREATE PROCEDURE wf_modify_auto_message
	vr_application_id			UUID,
	vr_autoMessageID			UUID,
	vr_bodyText			 VARCHAR(4000),
	vr_audienceType			varchar(20),
	vr_ref_state_id				UUID,
	vr_node_id					UUID,
	vr_admin				 BOOLEAN,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_bodyText = gfn_verify_string(vr_bodyText)
	
	IF vr_admin IS NULL SET vr_admin = 0
	
	UPDATE wf_auto_messages
		SET	BodyText = vr_bodyText,
			AudienceType = vr_audienceType,
			RefStateID = vr_ref_state_id,
			NodeID = vr_node_id,
			admin = vr_admin,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND AutoMessageID = vr_autoMessageID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_auto_message;

CREATE PROCEDURE wf_arithmetic_delete_auto_message
	vr_application_id			UUID,
	vr_autoMessageID			UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_auto_messages
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND AutoMessageID = vr_autoMessageID
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_p_get_owner_auto_messages;

CREATE PROCEDURE wf_p_get_owner_auto_messages
	vr_application_id	UUID,
	vr_owner_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids SELECT * FROM vr_owner_idsTemp
	
	SELECT am.auto_message_id AS auto_message_id,
		   am.owner_id AS owner_id,
		   am.body_text AS body_text,
		   am.audience_type AS audience_type,
		   am.ref_state_id AS ref_state_id,
		   st.title AS ref_state_title,
		   am.node_id AS node_id,
		   nd.node_name AS node_name,
		   nd.node_type_id AS node_type_id,
		   nd.type_name AS node_type,
		   am.admin AS admin
	FROM vr_owner_ids AS ref
		INNER JOIN wf_auto_messages AS am
		ON am.owner_id = ref.value
		LEFT JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = am.ref_state_id
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = am.node_id
	WHERE am.application_id = vr_application_id AND am.deleted = FALSE
	ORDER BY am.creation_date ASC
END;


DROP PROCEDURE IF EXISTS wf_get_owner_auto_messages;

CREATE PROCEDURE wf_get_owner_auto_messages
	vr_application_id	UUID,
	vr_strOwnerIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	INSERT INTO vr_owner_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strOwnerIDs, vr_delimiter) AS ref
	
	EXEC wf_p_get_owner_auto_messages vr_application_id, vr_owner_ids
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_auto_messages;

CREATE PROCEDURE wf_get_workflow_auto_messages
	vr_application_id	UUID,
	vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	
	INSERT INTO vr_owner_ids
	SELECT ID
	FROM wf_state_connections
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND deleted = FALSE
	
	EXEC wf_p_get_owner_auto_messages vr_application_id, vr_owner_ids
END;


DROP PROCEDURE IF EXISTS wf_get_connection_auto_messages;

CREATE PROCEDURE wf_get_connection_auto_messages
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_inStateID		UUID,
	vr_outStateID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_owner_ids GuidTableType
	
	INSERT INTO vr_owner_ids
	SELECT ID
	FROM wf_state_connections
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND 
		InStateID = vr_inStateID AND OutStateID = vr_outStateID
	
	EXEC wf_p_get_owner_auto_messages vr_application_id, vr_owner_ids
END;


DROP PROCEDURE IF EXISTS wf_p_get_workflow_states;

CREATE PROCEDURE wf_p_get_workflow_states
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType
	INSERT INTO vr_stateIDs SELECT * FROM vr_stateIDsTemp
	
	SELECT wfs.id AS id,
		   wfs.state_id AS state_id,
		   wfs.workflow_id AS workflow_id,
		   wfs.description AS description,
		   tg.tag AS tag,
		   wfs.data_needs_type AS data_needs_type,
		   wfs.ref_data_needs_state_id AS ref_data_needs_state_id,
		   wfs.data_needs_description AS data_needs_description,
		   wfs.description_needed AS description_needed,
		   wfs.hide_owner_name AS hide_owner_name,
		   wfs.edit_permission AS edit_permission,
		   wfs.response_type AS response_type,
		   wfs.ref_state_id AS ref_state_id,
		   wfs.node_id AS node_id,
		   nd.node_name AS node_name,
		   nd.node_type_id AS node_type_id,
		   nd.type_name AS node_type,
		   wfs.admin AS admin,
		   wfs.free_data_need_requests AS free_data_need_requests,
		   wfs.max_allowed_rejections AS max_allowed_rejections,
		   wfs.rejection_title AS rejection_title,
		   wfs.rejection_ref_state_id AS rejection_ref_state_id,
		   rs.title AS rejection_ref_state_title,
		   pl.poll_id,
		   pl.name AS poll_name
	FROM vr_stateIDs AS external_ids
		INNER JOIN wf_workflow_states AS wfs
		ON wfs.state_id = external_ids.value
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = wfs.node_id AND nd.deleted = FALSE
		LEFT JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = wfs.tag_id
		LEFT JOIN wf_states AS rs
		ON rs.application_id = vr_application_id AND rs.state_id = wfs.rejection_ref_state_id
		LEFT JOIN fg_polls AS pl
		ON pl.application_id = vr_application_id AND pl.poll_id = wfs.poll_id
	WHERE wfs.application_id = vr_application_id AND wfs.workflow_id = vr_workflow_id
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_states;

CREATE PROCEDURE wf_get_workflow_states
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_strStateIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_all BOOLEAN = NULL, vr_stateIDs GuidTableType
	
	IF vr_strStateIDs IS NULL BEGIN
		INSERT INTO vr_stateIDs
		SELECT StateID
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND deleted = FALSE
	END
	ELSE BEGIN
		INSERT INTO vr_stateIDs
		SELECT DISTINCT ref.value 
		FROM gfn_str_to_guid_table(vr_strStateIDs, vr_delimiter) AS ref
	END
	
	EXEC wf_p_get_workflow_states vr_application_id, vr_workflow_id, vr_stateIDs
END;


DROP PROCEDURE IF EXISTS wf_get_first_workflow_state;

CREATE PROCEDURE wf_get_first_workflow_state
	vr_application_id	UUID,
	vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType
	
	INSERT INTO vr_stateIDs
	SELECT wfs.state_id
	FROM wf_workflow_states AS wfs
	WHERE wfs.application_id = vr_application_id AND wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE AND
		NOT EXISTS(
			SELECT TOP(1) * 
			FROM wf_state_connections AS sc
				INNER JOIN wf_workflow_states AS ref
				ON ref.application_id = vr_application_id AND ref.state_id = sc.in_state_id
			WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
				sc.out_state_id = wfs.state_id AND sc.deleted = FALSE AND ref.deleted = FALSE
		)
		
	IF (SELECT COUNT(*) FROM vr_stateIDs) = 1
		EXEC wf_p_get_workflow_states vr_application_id, vr_workflow_id, vr_stateIDs
END;


DROP PROCEDURE IF EXISTS wf_p_get_state_data_needs_by_ids;

CREATE PROCEDURE wf_p_get_state_data_needs_by_ids
	vr_application_id	UUID,
	vr_iDsTemp		GuidTripleTableType readonly --First:WorkFlowID, Second:StateID, Third:NodeTypeID
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs GuidTripleTableType
	INSERT INTO vr_iDs SELECT * FROM vr_iDsTemp
	
	SELECT sdn.id AS id,
		   sdn.state_id AS state_id,
		   sdn.workflow_id AS workflow_id,
		   sdn.node_type_id AS node_type_id,
		   ef.form_id AS form_id,
		   ef.title AS form_title,
		   sdn.description AS description,
		   nt.name AS node_type,
		   sdn.multiple_select AS multi_select,
		   sdn.admin AS admin,
		   sdn.necessary AS necessary
	FROM vr_iDs AS external_ids
		INNER JOIN wf_state_data_needs AS sdn
		ON sdn.application_id = vr_application_id AND 
			external_ids.first_value = sdn.workflow_id AND
			external_ids.second_value = sdn.state_id AND 
			external_ids.third_value = sdn.node_type_id
		LEFT JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = sdn.node_type_id
		LEFT JOIN fg_form_owners AS fo
		INNER JOIN fg_extended_forms EF
		ON ef.application_id = vr_application_id AND ef.form_id = fo.form_id
		ON fo.application_id = vr_application_id AND fo.owner_id = sdn.id AND fo.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_p_get_state_data_needs;

CREATE PROCEDURE wf_p_get_state_data_needs
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType
	INSERT INTO vr_stateIDs SELECT * FROM vr_stateIDsTemp
	
	DECLARE vr_iDs GuidTripleTableType
	
	INSERT INTO vr_iDs
	SELECT vr_workflow_id, sdn.state_id, sdn.node_type_id
	FROM vr_stateIDs AS external_ids
		INNER JOIN wf_state_data_needs AS sdn
		ON sdn.state_id = external_ids.value
	WHERE sdn.application_id = vr_application_id AND 
		sdn.workflow_id = vr_workflow_id AND sdn.deleted = FALSE
	
	EXEC wf_p_get_state_data_needs_by_ids vr_application_id, vr_iDs
END;


DROP PROCEDURE IF EXISTS wf_get_state_data_needs;

CREATE PROCEDURE wf_get_state_data_needs
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_strStateIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_all BOOLEAN = NULL, vr_stateIDs GuidTableType
	
	IF vr_strStateIDs IS NULL 
		INSERT INTO vr_stateIDs
		SELECT StateID
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND deleted = FALSE
	ELSE BEGIN
		INSERT INTO vr_stateIDs
		SELECT DISTINCT ref.value 
		FROM gfn_str_to_guid_table(vr_strStateIDs, vr_delimiter) AS ref
	END
	
	EXEC wf_p_get_state_data_needs vr_application_id, vr_workflow_id, vr_stateIDs
END;


DROP PROCEDURE IF EXISTS wf_get_state_data_need;

CREATE PROCEDURE wf_get_state_data_need
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_iDs GuidTripleTableType
	INSERT INTO vr_iDs(FirstValue, SecondValue, ThirdValue)
	VALUES(vr_workflow_id, vr_stateID, vr_nodeTypeID)
	
	EXEC wf_p_get_state_data_needs_by_ids vr_application_id, vr_iDs
END;


DROP PROCEDURE IF EXISTS wf_get_current_state_data_needs;

CREATE PROCEDURE wf_get_current_state_data_needs
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_stateIDs GuidTableType, vr_data_needs_type varchar(20), 
		vr_ref_data_needs_state_id UUID
	
	SELECT vr_data_needs_type = DataNeedsType, vr_ref_data_needs_state_id = RefDataNeedsStateID
	FROM wf_workflow_states
	WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	
	IF vr_data_needs_type = 'RefState'
		INSERT INTO vr_stateIDs(Value) VALUES(vr_ref_data_needs_state_id)
	ELSE
		INSERT INTO vr_stateIDs(Value) VALUES(vr_stateID)
	
	EXEC wf_p_get_state_data_needs vr_application_id, vr_workflow_id, vr_stateIDs
END;


DROP PROCEDURE IF EXISTS wf_create_state_data_need_instance;

CREATE PROCEDURE wf_create_state_data_need_instance
	vr_application_id	UUID,
	vr_instanceID		UUID,
	vr_history_id		UUID,
	vr_node_id			UUID,
	vr_admin		 BOOLEAN,
	vr_form_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	INSERT INTO wf_state_data_need_instances(
		ApplicationID,
		InstanceID,
		HistoryID,
		NodeID,
		admin,
		Filled,
		AttachmentID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_instanceID,
		vr_history_id,
		vr_node_id,
		vr_admin,
		0,
		gen_random_uuid(),
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT 0
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_form_id IS NOT NULL BEGIN
		DECLARE vr_formInstanceID UUID = gen_random_uuid(), vr__result INTEGER
		
		DECLARE vr_formInstances FormInstanceTableType
			
		INSERT INTO vr_formInstances (InstanceID, FormID, OwnerID, DirectorID, admin)
		VALUES (vr_formInstanceID, vr_form_id, vr_instanceID, vr_node_id, vr_admin)
		
		EXEC fg_p_create_form_instance vr_application_id, vr_formInstances, vr_creator_user_id, vr_creation_date, vr__result output
			
		IF vr__result <= 0 BEGIN
			SELECT 0
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	-- Send Dashboards
	EXEC wf_p_send_dashboards vr_application_id, vr_history_id, NULL, NULL, NULL, 
		NULL, NULL, vr_instanceID, vr_creation_date, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'CannotDetermineDirector'
		ROLLBACK TRANSACTION 
		RETURN
	END
	-- end of Send Dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_set_state_data_need_instance_as_filled;

CREATE PROCEDURE wf_set_state_data_need_instance_as_filled
	vr_application_id			UUID,
	vr_instanceID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE wf_state_data_need_instances
		SET Filled = 1,
			FillingDate = vr_last_modification_date,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID AND Filled = 0
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr_formInstanceID UUID = (
		SELECT TOP(1) fi.instance_id
		FROM wf_state_data_need_instances AS dn
			INNER JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.owner_id = dn.instance_id
		WHERE dn.application_id = vr_application_id AND 
			dn.instance_id = vr_instanceID AND fi.filled = 0 AND fi.deleted = FALSE
	)
	
	DECLARE vr__result INTEGER = 0
	
	IF vr_formInstanceID IS NOT NULL BEGIN	
		EXEC fg_p_set_form_instance_as_filled vr_application_id, vr_formInstanceID, 
			vr_last_modification_date, vr_last_modifier_user_id, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	EXEC ntfn_p_set_dashboards_as_done vr_application_id, NULL, NULL, vr_instanceID, 
		N'WorkFlow', NULL, vr_last_modification_date, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_set_state_data_need_instance_as_not_filled;

CREATE PROCEDURE wf_set_state_data_need_instance_as_not_filled
	vr_application_id			UUID,
	vr_instanceID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE wf_state_data_need_instances
		SET Filled = 0,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID AND Filled = 1
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr_formInstanceID UUID = (
		SELECT TOP(1) fi.instance_id
		FROM wf_state_data_need_instances AS dn
			INNER JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.owner_id = dn.instance_id
		WHERE dn.application_id = vr_application_id AND
			dn.instance_id = vr_instanceID AND fi.filled = 1 AND fi.deleted = FALSE
	)
		
	DECLARE vr__result INTEGER
		
	IF vr_formInstanceID IS NOT NULL BEGIN
		EXEC fg_p_set_form_instance_as_not_filled vr_application_id, 
			vr_formInstanceID, vr_last_modifier_user_id, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	EXEC wf_p_send_dashboards vr_application_id, NULL, NULL, NULL, NULL, NULL, NULL, 
		vr_instanceID, vr_last_modification_date, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'CannotDetermineDirector'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_state_data_need_instance;

CREATE PROCEDURE wf_arithmetic_delete_state_data_need_instance
	vr_application_id			UUID,
	vr_instanceID				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE wf_state_data_need_instances
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND InstanceID = vr_instanceID AND deleted = FALSE
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr__result INTEGER = 0
	
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, NULL, vr_instanceID, N'WorkFlow', NULL, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_p_get_state_data_need_instances;

CREATE PROCEDURE wf_p_get_state_data_need_instances
	vr_application_id		UUID,
	vr_instanceIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	INSERT INTO vr_instanceIDs SELECT * FROM vr_instanceIDsTemp
	
	SELECT sdni.instance_id AS instance_id,
		   sdni.history_id AS history_id,
		   sdni.node_id AS node_id,
		   nd.node_name AS node_name,
		   nd.node_type_id AS node_type_id,
		   sdni.filled AS filled,
		   sdni.filling_date AS filling_date,
		   sdni.attachment_id AS attachment_id
	FROM vr_instanceIDs AS external_ids
		INNER JOIN wf_state_data_need_instances AS sdni
		ON sdni.instance_id = external_ids.value
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = sdni.node_id
	WHERE sdni.application_id = vr_application_id AND sdni.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_get_state_data_need_instance;

CREATE PROCEDURE wf_get_state_data_need_instance
	vr_application_id	UUID,
	vr_instanceID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_instanceIDs GuidTableType
	
	INSERT INTO vr_instanceIDs(Value)
	VALUES(vr_instanceID)
	
	EXEC wf_p_get_state_data_need_instances vr_application_id, vr_instanceIDs
END;


DROP PROCEDURE IF EXISTS wf_get_state_data_need_instances;

CREATE PROCEDURE wf_get_state_data_need_instances
	vr_application_id	UUID,
	vr_strHistoryIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_history_ids GuidTableType, vr_instanceIDs GuidTableType
	
	INSERT INTO vr_history_ids
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strHistoryIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_instanceIDs
	SELECT sdni.instance_id
	FROM vr_history_ids AS external_ids
		INNER JOIN wf_state_data_need_instances AS sdni
		ON sdni.history_id = external_ids.value
	WHERE sdni.application_id = vr_application_id AND sdni.deleted = FALSE
	
	EXEC wf_p_get_state_data_need_instances vr_application_id, vr_instanceIDs
END;


DROP PROCEDURE IF EXISTS wf_p_get_workflow_connections;

CREATE PROCEDURE wf_p_get_workflow_connections
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_inStateIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_inStateIDs GuidTableType
	INSERT INTO vr_inStateIDs SELECT * FROM vr_inStateIDsTemp
	
	SELECT sc.id AS id,
		   sc.workflow_id AS workflow_id,
		   sc.in_state_id AS in_state_id,
		   sc.out_state_id AS out_state_id,
		   sc.sequence_number AS sequence_number,
		   sc.label AS connection_label,
		   sc.attachment_required AS attachment_required,
		   sc.attachment_title AS attachment_title,
		   sc.node_required AS node_required,
		   sc.node_type_id AS node_type_id,
		   nt.name AS node_type,
		   sc.node_type_description AS node_type_description
	FROM vr_inStateIDs AS external_ids
		INNER JOIN wf_state_connections AS sc
		ON sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND
			sc.in_state_id = external_ids.value AND sc.deleted = FALSE
		INNER JOIN wf_states AS s
		ON s.application_id = vr_application_id AND s.state_id = sc.out_state_id AND s.deleted = FALSE
		LEFT JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = sc.node_type_id
	ORDER BY COALESCE(sc.sequence_number, 1000000) ASC, sc.creation_date ASC
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_connections;

CREATE PROCEDURE wf_get_workflow_connections
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_strInStateIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_all BOOLEAN = NULL, vr_inStateIDs GuidTableType
	
	IF vr_strInStateIDs IS NULL
		INSERT INTO vr_inStateIDs
		SELECT StateID
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND deleted = FALSE
	ELSE BEGIN
		INSERT INTO vr_inStateIDs
		SELECT DISTINCT ref.value 
		FROM gfn_str_to_guid_table(vr_strInStateIDs, vr_delimiter) AS ref
	END
	
	EXEC wf_p_get_workflow_connections vr_application_id, vr_workflow_id, vr_inStateIDs
END;


DROP PROCEDURE IF EXISTS wf_p_get_workflow_connection_forms;

CREATE PROCEDURE wf_p_get_workflow_connection_forms
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_inStateIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_inStateIDs GuidTableType
	INSERT INTO vr_inStateIDs SELECT * FROM vr_inStateIDsTemp
	
	SELECT scf.workflow_id AS workflow_id,
		   scf.in_state_id AS in_state_id,
		   scf.out_state_id AS out_state_id,
		   scf.form_id AS form_id,
		   ef.title AS form_title,
		   scf.description AS description,
		   scf.necessary AS necessary
	FROM vr_inStateIDs AS external_ids
		INNER JOIN wf_state_connection_forms AS scf
		ON scf.in_state_id = external_ids.value
		LEFT JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = scf.form_id
	WHERE scf.application_id = vr_application_id AND WorkFlowID = vr_workflow_id AND scf.deleted = FALSE
END;

	
DROP PROCEDURE IF EXISTS wf_get_workflow_connection_forms;

CREATE PROCEDURE wf_get_workflow_connection_forms
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_strInStateIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_inStateIDs GuidTableType
	
	IF vr_strInStateIDs IS NULL BEGIN
		INSERT INTO vr_inStateIDs
		SELECT StateID
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND deleted = FALSE
	END
	ELSE BEGIN
		INSERT INTO vr_inStateIDs
		SELECT DISTINCT ref.value
		FROM gfn_str_to_guid_table(vr_strInStateIDs, vr_delimiter) AS ref
	END
	
	EXEC wf_p_get_workflow_connection_forms vr_application_id, vr_workflow_id, vr_inStateIDs
END;


DROP PROCEDURE IF EXISTS wf_p_get_history_by_ids;

CREATE PROCEDURE wf_p_get_history_by_ids
	vr_application_id	UUID,
	vr_history_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_history_ids GuidTableType
	INSERT INTO vr_history_ids SELECT * FROM vr_history_idsTemp
	
	SELECT h.history_id AS history_id,
		   h.previous_history_id AS previous_history_id,
		   h.owner_id AS owner_id,
		   h.workflow_id AS workflow_id,
		   h.director_node_id,
		   h.director_user_id,
		   n.node_name AS director_node_name,
		   n.type_name AS director_node_type,
		   h.state_id AS state_id,
		   s.title AS state_title,
		   h.selected_out_state_id AS selected_out_state_id,
		   h.description AS description,
		   h.actor_user_id AS sender_user_id,
		   u.username AS sender_username,
		   u.first_name AS sender_first_name,
		   u.last_name AS sender_last_name,
		   h.send_date AS send_date,
		   (
				SELECT TOP(1) PollID
				FROM fg_polls AS p
				WHERE p.application_id = vr_application_id AND 
					p.owner_id = h.history_id AND p.deleted = FALSE
				ORDER BY p.creation_date DESC
		   ) AS poll_id,
		   (
				SELECT TOP(1) ref.name
				FROM fg_polls AS p
					INNER JOIN fg_polls AS ref
					ON ref.application_id = vr_application_id AND ref.poll_id = p.is_copy_of_poll_id
				WHERE p.application_id = vr_application_id AND 
					p.owner_id = h.history_id AND p.deleted = FALSE
				ORDER BY p.creation_date DESC
		   ) AS poll_name
	FROM vr_history_ids AS external_ids
		INNER JOIN wf_history AS h
		ON h.application_id = vr_application_id AND h.history_id = external_ids.value
		INNER JOIN wf_states AS s
		ON s.application_id = vr_application_id AND s.state_id = h.state_id
		LEFT JOIN cn_view_nodes_normal AS n
		ON n.application_id = vr_application_id AND n.node_id = h.director_node_id
		LEFT JOIN users_normal AS u
		ON u.application_id = vr_application_id AND u.user_id = h.actor_user_id
	ORDER BY h.id DESC
END;


DROP PROCEDURE IF EXISTS wf_get_history_by_ids;

CREATE PROCEDURE wf_get_history_by_ids
	vr_application_id	UUID,
	vr_strHistoryIDs	varchar(max),
	vr_delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_history_ids GuidTableType
	INSERT INTO vr_history_ids 
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strHistoryIDs, vr_delimiter) AS ref
	
	EXEC wf_p_get_history_by_ids vr_application_id, vr_history_ids
END;


DROP PROCEDURE IF EXISTS wf_get_history;

CREATE PROCEDURE wf_get_history
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_history_ids GuidTableType
	
	INSERT INTO vr_history_ids	
	SELECT HistoryID
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	
	EXEC wf_p_get_history_by_ids vr_application_id, vr_history_ids
END;


DROP PROCEDURE IF EXISTS wf_get_last_history;

CREATE PROCEDURE wf_get_last_history
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_stateID		UUID,
	vr_done		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_history_ids GuidTableType
	
	INSERT INTO vr_history_ids	
	SELECT TOP(1) HistoryID
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND 
		(vr_stateID IS NULL OR StateID = vr_stateID) AND deleted = FALSE AND
		(COALESCE(vr_done, 0) = 0 OR ActorUserID IS NOT NULL)
	ORDER BY ID DESC
	
	EXEC wf_p_get_history_by_ids vr_application_id, vr_history_ids
END;


DROP PROCEDURE IF EXISTS wf_get_last_selected_state_id;

CREATE PROCEDURE wf_get_last_selected_state_id
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_inStateID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_inStateID IS NULL BEGIN
		SELECT TOP(1) StateID AS id
		FROM wf_history
		WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
		ORDER BY ID DESC
	END
	ELSE BEGIN
		DECLARE vr_sendDate TIMESTAMP
		
		SET vr_sendDate = (
			SELECT TOP(1) SendDate 
			FROM wf_history
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND 
				StateID = vr_inStateID AND deleted = FALSE
			ORDER BY ID DESC
		)
		
		IF vr_sendDate IS NOT NULL BEGIN
			SELECT TOP(1) StateID AS id
			FROM wf_history
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND 
				SendDate > vr_sendDate AND deleted = FALSE
			ORDER BY ID DESC
		END
	END
END;


DROP PROCEDURE IF EXISTS wf_get_history_owner_id;

CREATE PROCEDURE wf_get_history_owner_id
	vr_application_id	UUID,
	vr_history_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT OwnerID AS id
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND HistoryID = vr_history_id 
END;


DROP PROCEDURE IF EXISTS wf_create_history_form_instance;

CREATE PROCEDURE wf_create_history_form_instance	
	vr_application_id	UUID,
	vr_history_id		UUID,
	vr_outStateID		UUID,
	vr_form_id			UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_formOwnerID UUID = NULL, vr_formDirectorID UUID,
		vr_formInstanceID UUID = gen_random_uuid(), vr_admin BOOLEAN,
		vr_workflow_id UUID, vr_stateID UUID
	
	SELECT vr_formDirectorID = COALESCE(DirectorNodeID, DirectorUserID), 
		vr_workflow_id = WorkFlowID, vr_stateID = StateID
	FROM wf_history 
	WHERE ApplicationID = vr_application_id AND HistoryID = vr_history_id
	
	SET vr_admin = (
		SELECT TOP(1) admin 
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND 
			WorkFlowID = vr_workflow_id AND StateID = vr_stateID
	)
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM wf_history_form_instances
		WHERE ApplicationID = vr_application_id AND 
			HistoryID = vr_history_id AND OutStateID = vr_outStateID
	) BEGIN
		UPDATE wf_history_form_instances
			SET deleted = FALSE,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND 
			HistoryID = vr_history_id AND OutStateID = vr_outStateID
	END
	ELSE BEGIN
		SET vr_formOwnerID = gen_random_uuid()
		
		INSERT INTO wf_history_form_instances(
			ApplicationID,
			HistoryID,
			OutStateID,
			FormsID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			vr_history_id,
			vr_outStateID,
			vr_formOwnerID,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT NULL AS id
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF vr_formOwnerID IS NULL BEGIN
		SET vr_formOwnerID = (
			SELECT FormsID 
			FROM wf_history_form_instances
			WHERE ApplicationID = vr_application_id AND 
				HistoryID = vr_history_id AND OutStateID = vr_outStateID
		)
	END
	
	DECLARE vr__result INTEGER
	
	DECLARE vr_formInstances FormInstanceTableType
			
	INSERT INTO vr_formInstances (InstanceID, FormID, OwnerID, DirectorID, admin)
	VALUES (vr_formInstanceID, vr_form_id, vr_formOwnerID, vr_formDirectorID, vr_admin)
	
	EXEC fg_p_create_form_instance vr_application_id, vr_formInstances, vr_creator_user_id, vr_creation_date, vr__result output
		
	IF vr__result <= 0 BEGIN
		SELECT NULL AS id
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT vr_formInstanceID AS id
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_get_history_form_instances;

CREATE PROCEDURE wf_get_history_form_instances
	vr_application_id	UUID,
	vr_strHistoryIDs	varchar(max),
	vr_delimiter		char,
	vr_selected	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_selected = 0 SET vr_selected = NULL
	
	DECLARE vr_history_ids GuidTableType
	INSERT INTO vr_history_ids 
	SELECT DISTINCT ref.value FROM gfn_str_to_guid_table(vr_strHistoryIDs, vr_delimiter) AS ref
	
	SELECT hfi.history_id AS history_id,
		   hfi.out_state_id AS out_state_id,
		   hfi.forms_id AS forms_id
	FROM vr_history_ids AS external_ids
		INNER JOIN wf_history AS hs
		ON hs.application_id = vr_application_id AND hs.history_id = external_ids.value
		INNER JOIN wf_history_form_instances AS hfi
		ON hfi.application_id = vr_application_id AND hfi.history_id = hs.history_id
	WHERE (vr_selected IS NULL OR 
		(hs.selected_out_state_id IS NOT NULL AND hs.selected_out_state_id = hfi.out_state_id)) AND
		hs.deleted = FALSE AND hfi.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_send_to_next_state;

CREATE PROCEDURE wf_send_to_next_state
	vr_application_id		UUID,
    vr_prev_history_id		UUID,
    vr_stateID			UUID,
    vr_director_node_id		UUID,
    vr_director_user_id		UUID,
    vr_description	 VARCHAR(2000),
    vr_reject			 BOOLEAN,
    vr_senderUserID		UUID,
    vr_sendDate		 TIMESTAMP,
	vr_attachedFilesTemp	DocFileInfoTableType ReadOnly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_attachedFiles DocFileInfoTableType
	INSERT INTO vr_attachedFiles SELECT * FROM vr_attachedFilesTemp
	
	SET vr_description = gfn_verify_string(vr_description)
	
	IF vr_reject IS NULL SET vr_reject = 0
	
	DECLARE vr_history_id UUID, vr_owner_id UUID,
		vr_workflow_id UUID, vr_prev_state_id UUID
	
	SELECT vr_history_id = gen_random_uuid(), vr_owner_id = OwnerID, 
		vr_workflow_id = WorkFlowID, vr_prev_state_id = StateID
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND HistoryID = vr_prev_history_id
	
	IF vr_reject = 0 BEGIN
		IF vr_director_node_id IS NULL AND vr_director_user_id IS NULL BEGIN
			SELECT -5, N'NoDirectorIsSet'
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	ELSE BEGIN
		DECLARE vr_max_allowed_rejections INTEGER, vr_rejection_ref_state_id UUID
		
		SELECT vr_max_allowed_rejections = MaxAllowedRejections, 
			   vr_rejection_ref_state_id = RejectionRefStateID
		FROM wf_workflow_states
		WHERE ApplicationID = vr_application_id AND WorkFlowID = vr_workflow_id AND StateID = vr_prev_state_id
		
		IF vr_max_allowed_rejections IS NULL OR vr_max_allowed_rejections <= 0 BEGIN
			SELECT -11, N'RejectionIsNotAllowed'
			ROLLBACK TRANSACTION
			RETURN
		END
		ELSE IF (
			SELECT COUNT(*) 
			FROM wf_history 
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND 
				WorkFlowID = vr_workflow_id AND StateID = vr_prev_history_id AND Rejected = 1 AND deleted = FALSE
		) >= vr_max_allowed_rejections BEGIN
			SELECT -12, N'MaxAllowedRejectionsExceeded'
			ROLLBACK TRANSACTION
			RETURN	
		END
		
		SELECT TOP(1) vr_director_node_id = DirectorNodeID, vr_director_user_id = DirectorUserID,
			vr_stateID = StateID
		FROM wf_history
		WHERE ApplicationID = vr_application_id AND 
			OwnerID = vr_owner_id AND WorkFlowID = vr_workflow_id AND 
			(vr_rejection_ref_state_id IS NULL OR StateID = vr_rejection_ref_state_id) AND
			HistoryID <> vr_prev_history_id AND deleted = FALSE
		ORDER BY ID DESC
	END
	
	UPDATE wf_history
		SET Rejected = vr_reject,
			SelectedOutStateID = vr_stateID,
			description = vr_description,
			ActorUserID = vr_senderUserID
	WHERE ApplicationID = vr_application_id AND HistoryID = vr_prev_history_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -6, N'HistoryUpdateFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	INSERT INTO wf_history(
		ApplicationID,
		HistoryID,
		PreviousHistoryID,
		OwnerID,
		WorkFlowID,
		StateID,
		DirectorNodeID,
		DirectorUserID,
		Rejected,
		Terminated,
		SenderUserID,
		SendDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_history_id,
		vr_prev_history_id,
		vr_owner_id, 
		vr_workflow_id, 
		vr_stateID, 
		vr_director_node_id, 
		vr_director_user_id, 
		0,
		0,
		vr_senderUserID, 
		vr_sendDate, 
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -7, N'HistoryUpdateFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr_data_needs_type varchar(20), vr_ref_data_needs_state_id UUID,
		vr_form_id UUID
		
	SELECT vr_data_needs_type = wfs.data_needs_type, 
		   vr_ref_data_needs_state_id = wfs.ref_data_needs_state_id,
		   vr_form_id = fo.form_id
	FROM wf_workflow_states AS wfs
		LEFT JOIN fg_form_owners AS fo
		ON fo.application_id = vr_application_id AND fo.owner_id = wfs.id
	WHERE wfs.application_id = vr_application_id AND 
		wfs.workflow_id = vr_workflow_id AND wfs.state_id = vr_stateID
	
	DECLARE vr__result INTEGER
	
	IF vr_data_needs_type = 'RefState' BEGIN
		IF EXISTS(
			SELECT TOP(1) * 
			FROM wf_state_data_need_instances
			WHERE ApplicationID = vr_application_id AND HistoryID = vr_prev_history_id AND deleted = FALSE
		) BEGIN
			DECLARE vr__new_needs Table(InstanceID UUID, 
				NodeID UUID, admin BOOLEAN)
		
			INSERT INTO wf_state_data_need_instances(
				ApplicationID,
				InstanceID,
				HistoryID,
				NodeID,
				admin,
				Filled,
				CreatorUserID,
				CreationDate,
				Deleted
			)
			SELECT vr_application_id, gen_random_uuid(), vr_history_id, NodeID, 
				admin, 0, vr_senderUserID, vr_sendDate, 0
			FROM wf_state_data_need_instances
			WHERE ApplicationID = vr_application_id AND HistoryID = vr_prev_history_id AND deleted = FALSE
			
			IF @vr_rowcount <= 0 BEGIN
				SELECT -8, N'HistoryDateNeedsCreationFailed'
				ROLLBACK TRANSACTION
				RETURN
			END
		END
		
		EXEC fg_p_copy_form_instances vr_application_id, vr_prev_history_id, 
			vr_history_id, vr_form_id, vr_senderUserID, vr_sendDate, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -9, N'HistoryFormInstancesCopyFailed'
			ROLLBACK TRANSACTION
			RETURN	
		END
	END
	
	IF EXISTS(SELECT TOP(1) * FROM vr_attachedFiles) BEGIN
		EXEC dct_p_add_files vr_application_id, 
			vr_prev_history_id, N'WorkFlow', vr_attachedFiles, vr_senderUserID, vr_sendDate, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -10, N'FileAttachmentFailed'
			ROLLBACK TRANSACTION 
			RETURN
		END
	END
	
	-- Update WFState in CN_Nodes Table
	DECLARE vr_stateTitle VARCHAR(1000) = (
		SELECT s.title
		FROM wf_states AS s
		WHERE s.application_id = vr_application_id AND s.state_id = vr_stateID
	)
	
	DECLARE vr_hide_contributors BOOLEAN = (
		SELECT TOP(1) COALESCE(s.hide_owner_name, 0)
		FROM wf_workflow_states AS s
		WHERE s.application_id = vr_application_id AND 
			s.workflow_id = vr_workflow_id AND s.state_id = vr_stateID
	)
	
	EXEC cn_p_modify_node_wf_state vr_application_id, vr_owner_id, 
		vr_stateTitle, vr_hide_contributors, vr_senderUserID, vr_sendDate, vr__result output
		
	IF vr__result <= 0 BEGIN
		SELECT -11, N'StatusUpdateFailed'
		ROLLBACK TRANSACTION 
		RETURN
	END
	-- end of Update WFState in CN_Nodes Table
	
	-- Send Dashboards
	EXEC ntfn_p_set_dashboards_as_done vr_application_id, vr_senderUserID, vr_owner_id, 
		vr_prev_history_id, N'WorkFlow', NULL, vr_sendDate, vr__result output 
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'UpdatingDashboardsFailed'
		ROLLBACK TRANSACTION 
		RETURN
	END
	
	EXEC wf_p_send_dashboards vr_application_id, vr_history_id, vr_owner_id, vr_workflow_id, 
		vr_stateID, vr_director_user_id, vr_director_node_id, NULL, vr_sendDate, vr__result output
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'CannotDetermineDirector'
		ROLLBACK TRANSACTION 
		RETURN
	END
	-- end of Send Dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_terminate_workflow;

CREATE PROCEDURE wf_terminate_workflow
	vr_application_id		UUID,
    vr_prev_history_id		UUID,
    vr_description	 VARCHAR(2000),
    vr_senderUserID		UUID,
    vr_sendDate		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_description = gfn_verify_string(vr_description)
	
	DECLARE vr_owner_id UUID, vr_workflow_id UUID
	
	SELECT vr_owner_id = OwnerID, vr_workflow_id = WorkFlowID
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND HistoryID = vr_prev_history_id
	
	UPDATE wf_history
		SET Terminated = 1,
			description = vr_description,
			ActorUserID = vr_senderUserID
	WHERE ApplicationID = vr_application_id AND HistoryID = vr_prev_history_id
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -6
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Send Dashboards
	DECLARE vr__result INTEGER
	
	EXEC ntfn_p_set_dashboards_as_done vr_application_id, vr_senderUserID, vr_owner_id, 
		vr_prev_history_id, N'WorkFlow', NULL, vr_sendDate, vr__result output 
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'RemovingDashboardsFailed'
		ROLLBACK TRANSACTION 
		RETURN
	END
	
	EXEC ntfn_p_arithmetic_delete_dashboards vr_application_id, 
		NULL, vr_owner_id, NULL, N'WorkFlow', NULL, vr__result output 
	
	IF vr__result <= 0 BEGIN
		SELECT -1, N'RemovingDashboardsFailed'
		ROLLBACK TRANSACTION 
		RETURN
	END
	-- end of Send Dashboards
	
	SELECT 1
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_get_viewer_status;

CREATE PROCEDURE wf_get_viewer_status
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_has_workflow BOOLEAN = 0
	SELECT vr_has_workflow = 1 
	WHERE EXISTS(
		SELECT TOP(1) * 
		FROM wf_history 
		WHERE ApplicationID = vr_application_id AND owner_id = vr_owner_id AND deleted = FALSE
	)
		
	IF vr_has_workflow = 0 BEGIN
		SELECT N'NotInWorkFlow'
		RETURN
	END
	
	DECLARE vr_isOwner BOOLEAN
	EXEC cn_p_is_node_creator vr_application_id, vr_owner_id, vr_user_id, vr_isOwner output
	
	IF vr_isOwner IS NULL SET vr_isOwner = 0
	
	DECLARE vr_workflow_id UUID, vr_stateID UUID,
		vr_director_node_id UUID, vr_director_user_id UUID
	
	SELECT TOP(1) vr_workflow_id = WorkFlowID, vr_stateID = StateID,
		vr_director_node_id = DirectorNodeID, vr_director_user_id = DirectorUserID
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	ORDER BY ID DESC
	
	IF vr_user_id = vr_director_user_id 
		SELECT N'Director'
	ELSE BEGIN
		DECLARE vr_isAdminFromWorkFlow BOOLEAN, vr_isNodeMember BOOLEAN, vr_isAdmin BOOLEAN = 0
		
		EXEC cn_p_is_node_member vr_application_id, 
			vr_director_node_id, vr_user_id, vr_isAdmin, 'Accepted', vr_isNodeMember output
		
		IF vr_isNodeMember = 1 BEGIN
			SET vr_isAdminFromWorkFlow = (
				SELECT admin 
				FROM wf_workflow_states
				WHERE ApplicationID = vr_application_id AND 
					WorkFlowID = vr_workflow_id AND StateID = vr_stateID
			)
			
			IF vr_isAdminFromWorkFlow IS NULL SET vr_isAdminFromWorkFlow = 0
			
			IF vr_isAdminFromWorkFlow = 1 BEGIN
				EXEC cn_p_is_node_admin vr_application_id, 
					vr_director_node_id, vr_user_id, vr_isAdmin output
			END
		END
		ELSE BEGIN
			IF vr_isOwner = 1 SELECT N'Owner'
			ELSE SELECT N'None'
			
			RETURN
		END
		
		IF (vr_isAdminFromWorkFlow = 0 OR vr_isAdmin = 1) SELECT N'Director'
		ELSE SELECT N'DirectorNodeMember'
	END	
END;


DROP PROCEDURE IF EXISTS wf_get_next_state_params;

CREATE PROCEDURE wf_get_next_state_params
	vr_application_id	UUID,
	vr_node_id			UUID,
    vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_startStateID UUID
	DECLARE vr_response_type varchar(20)
	DECLARE vr_director_node_id UUID
	DECLARE vr_director_user_id UUID
	
	DECLARE vr__start_state_ids GuidTableType
	INSERT INTO vr__start_state_ids
	SELECT wfs.state_id
	FROM wf_workflow_states AS wfs
	WHERE wfs.application_id = vr_application_id AND 
		wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE AND
		NOT EXISTS(
			SELECT TOP(1) * 
			FROM wf_state_connections AS sc
				INNER JOIN wf_workflow_states AS ref
				ON ref.application_id = vr_application_id AND ref.state_id = sc.in_state_id
			WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
				sc.out_state_id = wfs.state_id AND sc.deleted = FALSE AND ref.deleted = FALSE
		)
		
	SET vr_startStateID = (SELECT TOP(1) ref.value FROM vr__start_state_ids AS ref)
		
	SELECT vr_response_type = ResponseType, vr_director_node_id = NodeID
	FROM wf_workflow_states
	WHERE ApplicationID = vr_application_id AND 
		WorkFlowID = vr_workflow_id AND StateID = vr_startStateID AND deleted = FALSE
	
	IF vr_response_type = 'SendToOwner' BEGIN
		SET vr_director_node_id = NULL
		
		SET vr_director_user_id = (
			SELECT TOP(1) CreatorUserID 
			FROM cn_nodes 
			WHERE ApplicationID = vr_application_id AND NodeID = vr_node_id
		)
	END
	ELSE IF vr_response_type = 'RefState'
		SET vr_director_node_id = NULL
END;


DROP PROCEDURE IF EXISTS wf_p_start_new_workflow;

CREATE PROCEDURE wf_p_start_new_workflow
	vr_application_id	UUID,
	vr_node_id			UUID,
    vr_workflow_id		UUID,
    vr_director_node_id	UUID,
	vr_director_user_id	UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP,
	vr__result	 INTEGER output,
	vr__message		varchar(500) output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_terminated BOOLEAN = NULL
	DECLARE vr_previous_history_id UUID = NULL
	
	SELECT TOP(1) vr_terminated = Terminated, vr_previous_history_id = HistoryID
	FROM wf_history 
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_node_id AND deleted = FALSE
	ORDER BY ID DESC
	
	IF vr_terminated = 0 BEGIN -- If result is null or equals 1, workflow doesn't exist or has been terminated
		SET vr__result = -1
		SET vr__message = N'TheNodeIsAlreadyInWorkFlow'
		RETURN
	END
	
	DECLARE vr_startStateID UUID
	DECLARE vr_response_type varchar(20)
	
	DECLARE vr__start_state_ids GuidTableType
	
	INSERT INTO vr__start_state_ids
	SELECT wfs.state_id
	FROM wf_workflow_states AS wfs
	WHERE wfs.application_id = vr_application_id AND wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE AND
		NOT EXISTS(
			SELECT TOP(1) * 
			FROM wf_state_connections AS sc
				INNER JOIN wf_workflow_states AS ref
				ON ref.application_id = vr_application_id AND ref.state_id = sc.in_state_id
			WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
				sc.out_state_id = wfs.state_id AND sc.deleted = FALSE AND ref.deleted = FALSE
		)
		
	IF (SELECT COUNT(*) FROM vr__start_state_ids) <> 1 BEGIN
		SET vr__result = -1
		SET vr__message = N'WorkFlowStateNotFound'
		RETURN
	END
	ELSE
		SET vr_startStateID = (SELECT TOP(1) ref.value FROM vr__start_state_ids AS ref)
	
	DECLARE vr_history_id UUID = gen_random_uuid()
	
	INSERT INTO wf_history(
		ApplicationID,
		HistoryID,
		OwnerID,
		WorkFlowID,
		StateID,
		PreviousHistoryID,
		DirectorNodeID,
		DirectorUserID,
		Rejected,
		Terminated,
		SenderUserID,
		SendDate,
		Deleted
	)
	VALUES(
		vr_application_id,
		vr_history_id,
		vr_node_id,
		vr_workflow_id,
		vr_startStateID,
		vr_previous_history_id,
		vr_director_node_id,
		vr_director_user_id,
		0,
		0,
		vr_creator_user_id,
		vr_creation_date,
		0
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SET vr__result = -1
		SET vr__message = NULL
		RETURN
	END
	
	-- Update WFState in CN_Nodes Table
	DECLARE vr_stateTitle VARCHAR(1000) = (
		SELECT Title 
		FROM wf_states 
		WHERE ApplicationID = vr_application_id AND StateID = vr_startStateID
	)
	
	DECLARE vr_hide_contributors BOOLEAN = (
		SELECT TOP(1) COALESCE(s.hide_owner_name, 0)
		FROM wf_workflow_states AS s
		WHERE s.application_id = vr_application_id AND 
			s.workflow_id = vr_workflow_id AND s.state_id = vr_startStateID
	)
	
	EXEC cn_p_modify_node_wf_state vr_application_id, vr_node_id, 
		vr_stateTitle, vr_hide_contributors, vr_creator_user_id, vr_creation_date, vr__result output
		
	IF vr__result <= 0 BEGIN
		SET vr__result = -11
		SET vr__message = N'StatusUpdateFailed'
		RETURN
	END
	-- end of Update WFState in CN_Nodes Table
	
	-- Send Dashboards
	EXEC wf_p_send_dashboards vr_application_id, vr_history_id, vr_node_id, vr_workflow_id, 
		vr_startStateID, vr_director_user_id, vr_director_node_id, NULL, vr_creation_date, vr__result output
	
	IF vr__result <= 0 BEGIN
		SET vr__result = -1
		SET vr__message = N'CannotDetermineDirector'
		RETURN
	END
	-- end of Send Dashboards
	
	SET vr__result = 1
END;


DROP PROCEDURE IF EXISTS wf_restart_workflow;

CREATE PROCEDURE wf_restart_workflow
	vr_application_id	UUID,
	vr_owner_id		UUID,
	vr_director_node_id	UUID,
	vr_director_user_id	UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr__result INTEGER
	DECLARE vr__message varchar(500) = NULL
	
	DECLARE vr_workflow_id UUID
	
	SELECT TOP(1) vr_workflow_id = WorkFlowID
	FROM wf_history 
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id
	ORDER BY ID DESC
	
	IF vr_workflow_id IS NULL BEGIN
		SELECT -1, N'WorkFlowNotFound'
	END
	ELSE BEGIN
		EXEC wf_p_start_new_workflow vr_application_id, vr_owner_id, vr_workflow_id, vr_director_node_id,
			vr_director_user_id, vr_creator_user_id, vr_creation_date, vr__result output, vr__message output
	
		IF vr__result > 0 SELECT vr__result
		ELSE BEGIN 
			SELECT vr__result, vr__message
			ROLLBACK TRANSACTION
			RETURN
		END
	END
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS wf_has_workflow;

CREATE PROCEDURE wf_has_workflow
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 1 
	WHERE EXISTS(
		SELECT TOP(1) * 
		FROM wf_history 
		WHERE ApplicationID = vr_application_id AND owner_id = vr_owner_id AND deleted = FALSE
	)
END;


DROP PROCEDURE IF EXISTS wf_is_terminated;

CREATE PROCEDURE wf_is_terminated
	vr_application_id	UUID,
	vr_owner_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) Terminated
	FROM wf_history
	WHERE ApplicationID = vr_application_id AND OwnerID = vr_owner_id AND deleted = FALSE
	ORDER BY ID DESC
END;


DROP PROCEDURE IF EXISTS wf_get_service_abstract;

CREATE PROCEDURE wf_get_service_abstract
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_nodeTypeID		UUID,
	vr_user_id			UUID,
	vr_null_tag_label VARCHAR(256)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET vr_null_tag_label = gfn_verify_string(vr_null_tag_label)

	SELECT COALESCE(tg.tag, vr_null_tag_label) AS tag, counts.cnt AS count
	FROM
		(
			SELECT owners.tag_id, COUNT(OwnerID) AS cnt 
			FROM
				(
					SELECT a.owner_id, ws.tag_id
					FROM wf_history AS a
						INNER JOIN (
							SELECT OwnerID, MAX(ID) AS id
							FROM wf_history
							WHERE ApplicationID = vr_application_id AND deleted = FALSE
							GROUP BY OwnerID
						) AS b
						ON b.id = a.id AND b.owner_id = a.owner_id
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = a.owner_id
						INNER JOIN wf_workflow_states AS ws
						ON ws.application_id = vr_application_id AND ws.state_id = a.state_id
					WHERE a.application_id = vr_application_id AND
						(vr_workflow_id IS NULL OR 
							(a.workflow_id = vr_workflow_id AND ws.workflow_id = vr_workflow_id)
						) AND nd.node_type_id = vr_nodeTypeID AND nd.deleted = FALSE AND
						(vr_user_id IS NULL OR	
							EXISTS(
								SELECT TOP(1) * 
								FROM cn_node_creators
								WHERE ApplicationID = vr_application_id AND 
									NodeID = a.owner_id AND UserID = vr_user_id AND deleted = FALSE
							)
						)
				) AS owners
			GROUP BY owners.tag_id
		) AS counts
		LEFT JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = counts.tag_id
END;


DROP PROCEDURE IF EXISTS wf_get_service_user_ids;

CREATE PROCEDURE wf_get_service_user_ids
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT DISTINCT nc.user_id AS id
	FROM
		(
			SELECT DISTINCT OwnerID
			FROM wf_history
			WHERE ApplicationID = vr_application_id AND 
				(vr_workflow_id IS NULL OR WorkFlowID = vr_workflow_id) AND deleted = FALSE
		) AS nds
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nds.owner_id
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = nds.owner_id
	WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
		nd.deleted = FALSE AND nc.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_items_count;

CREATE PROCEDURE wf_get_workflow_items_count
	vr_application_id	UUID,
	vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT CAST(COUNT(DISTINCT h.owner_id) AS integer)
	FROM wf_history AS h
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = h.owner_id AND nd.deleted = FALSE
	WHERE h.application_id = vr_application_id AND h.workflow_id = vr_workflow_id AND h.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_state_items_count;

CREATE PROCEDURE wf_get_workflow_state_items_count
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_stateID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT CAST(COUNT(DISTINCT h.owner_id) AS integer)
	FROM wf_history AS h
		INNER JOIN (
			SELECT a.owner_id, MAX(a.id) AS id
			FROM wf_history AS a
			WHERE a.application_id = vr_application_id AND a.workflow_id = vr_workflow_id AND a.deleted = FALSE
			GROUP BY a.owner_id
		) AS x
		ON x.id = h.id
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = h.owner_id AND nd.deleted = FALSE
	WHERE h.application_id = vr_application_id AND h.state_id = vr_stateID
END;


DROP PROCEDURE IF EXISTS wf_get_user_workflow_items_count;

CREATE PROCEDURE wf_get_user_workflow_items_count
	vr_application_id			UUID,
	vr_user_id					UUID,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT counts.node_type_id AS node_type_id,
		   nt.name AS node_type, 
		   counts.cnt AS count
	FROM (
			SELECT nd.node_type_id, COUNT(nc.node_id) AS cnt
			FROM cn_node_creators AS nc
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
				INNER JOIN cn_services AS sr
				ON sr.application_id = vr_application_id AND sr.node_type_id = nd.node_type_id
			WHERE nc.application_id = vr_application_id AND nc.user_id = vr_user_id AND 
				EXISTS(
					SELECT TOP(1) * 
					FROM wf_history
					WHERE ApplicationID = vr_application_id AND OwnerID = nd.node_id AND deleted = FALSE
				) AND nc.deleted = FALSE AND nd.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nd.node_type_id
		) AS counts
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = counts.node_type_id
END;


DROP PROCEDURE IF EXISTS wf_add_owner_workflow;

CREATE PROCEDURE wf_add_owner_workflow
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_workflow_id		UUID,
	vr_creator_user_id	UUID,
	vr_creation_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM wf_workflow_owners
		WHERE ApplicationID = vr_application_id AND
			NodeTypeID = vr_nodeTypeID AND WorkFlowID = vr_workflow_id
	) BEGIN
		UPDATE wf_workflow_owners
			SET deleted = FALSE,
				LastModifierUserID = vr_creator_user_id,
				LastModificationDate = vr_creation_date
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_nodeTypeID AND WorkFlowID = vr_workflow_id
	END
	ELSE BEGIN
		INSERT INTO wf_workflow_owners(
			ApplicationID,
			ID,
			NodeTypeID,
			WorkFlowID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			vr_application_id,
			gen_random_uuid(),
			vr_nodeTypeID,
			vr_workflow_id,
			vr_creator_user_id,
			vr_creation_date,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_arithmetic_delete_owner_workflow;

CREATE PROCEDURE wf_arithmetic_delete_owner_workflow
	vr_application_id			UUID,
	vr_nodeTypeID				UUID,
	vr_workflow_id				UUID,
	vr_last_modifier_user_id		UUID,
	vr_last_modification_date TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE wf_workflow_owners
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_last_modification_date
	WHERE ApplicationID = vr_application_id AND 
		NodeTypeID = vr_nodeTypeID AND WorkFlowID = vr_workflow_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS wf_get_owner_workflows;

CREATE PROCEDURE wf_get_owner_workflows
	vr_application_id	UUID,
	vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_workflow_ids GuidTableType
	
	INSERT INTO vr_workflow_ids
	SELECT WorkFlowID
	FROM wf_workflow_owners
	WHERE ApplicationID = vr_application_id AND NodeTypeID = vr_nodeTypeID AND deleted = FALSE
	
	EXEC wf_p_get_workflows_by_ids vr_application_id, vr_workflow_ids
END;


DROP PROCEDURE IF EXISTS wf_get_owner_workflow_primary_key;

CREATE PROCEDURE wf_get_owner_workflow_primary_key
	vr_application_id	UUID,
	vr_nodeTypeID		UUID,
	vr_workflow_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT ID
	FROM wf_workflow_owners
	WHERE ApplicationID = vr_application_id AND 
		NodeTypeID = vr_nodeTypeID AND WorkFlowID = vr_workflow_id
END;


DROP PROCEDURE IF EXISTS wf_get_workflow_owner_ids;

CREATE PROCEDURE wf_get_workflow_owner_ids
	vr_application_id	UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT DISTINCT NodeTypeID AS id
	FROM wf_workflow_owners
	WHERE ApplicationID = vr_application_id AND deleted = FALSE
END;


DROP PROCEDURE IF EXISTS wf_get_form_instance_workflow_owner_id;

CREATE PROCEDURE wf_get_form_instance_workflow_owner_id
	vr_application_id		UUID,
	vr_formInstanceID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) h.owner_id
	FROM fg_form_instances AS fi
		INNER JOIN wf_history_form_instances AS hfi
		ON hfi.application_id = vr_application_id AND hfi.forms_id = fi.owner_id
		INNER JOIN wf_history AS h
		ON h.application_id = vr_application_id AND h.history_id = hfi.history_id
	WHERE fi.application_id = vr_application_id AND fi.instance_id = vr_formInstanceID
END;

DROP PROCEDURE IF EXISTS lg_save_log;

CREATE PROCEDURE lg_save_log
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_host_address		varchar(100),
	vr_host_name		 VARCHAR(255),
	vr_action				varchar(100),
	vr_level				varchar(20),
	vr_not_authorized	 BOOLEAN,
	vr_strSubjectIDs		varchar(max),
	vr_delimiter			char,
	vr_secondSubjectID	UUID,
	vr_third_subject_id		UUID,
	vr_fourth_subject_id	UUID,
	vr_date			 TIMESTAMP,
	vr_info			 VARCHAR(max),
	vr_module_identifier	varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_subjectIDs GuidTableType
	INSERT INTO vr_subjectIDs
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strSubjectIDs, vr_delimiter) AS ref

	INSERT INTO lg_logs(
		ApplicationID,
		UserID,
		HostAddress,
		HostName,
		action,
		level,
		NotAuthorized,
		SubjectID,
		SecondSubjectID,
		ThirdSubjectID,
		FourthSubjectID,
		date,
		Info,
		ModuleIdentifier
	)
	SELECT vr_application_id, vr_user_id, vr_host_address, vr_host_name, vr_action, vr_level, vr_not_authorized, ref.value, 
		vr_secondSubjectID, vr_third_subject_id, vr_fourth_subject_id, vr_date, vr_info, vr_module_identifier
	FROM vr_subjectIDs AS ref
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS lg_p_get_logs;

CREATE PROCEDURE lg_p_get_logs
	vr_application_id	UUID,
    vr_user_idsTemp	GuidTableType readonly,
    vr_actionsTemp	StringTableType readonly,
    vr_beginDate	 TIMESTAMP,
    vr_finish_date	 TIMESTAMP,
    vr_last_id			bigint,
    vr_count		 INTEGER
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	INSERT INTO vr_user_ids SELECT * FROM vr_user_idsTemp
	
    DECLARE vr_actions StringTableType
    INSERT INTO vr_actions SELECT * FROM vr_actionsTemp
	
	DECLARE vr_actionsCount INTEGER = (SELECT COUNT(*) FROM vr_actions)
	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	SET vr_count = COALESCE(vr_count, 100)
	
	IF vr_usersCount = 0 BEGIN
		SELECT TOP(vr_count) 
			lg.log_id,
			lg.user_id,
			un.username,
			un.first_name,
			un.last_name,
			lg.host_address,
			lg.host_name,
			lg.action,
			lg.date,
			lg.info,
			lg.module_identifier
		FROM lg_logs AS lg
			LEFT JOIN usr_view_users AS un
			ON un.user_id = lg.user_id
		WHERE (vr_application_id IS NULL OR lg.application_id = vr_application_id) AND
			(vr_last_id IS NULL OR LogID > vr_last_id) AND
			(vr_finish_date IS NULL OR lg.date < vr_finish_date) AND
			(vr_beginDate IS NULL OR lg.date > vr_beginDate) AND
			(vr_actionsCount = 0 OR lg.action IN (SELECT * FROM vr_actions))
		ORDER BY lg.log_id DESC
	END
	ELSE BEGIN
		SELECT TOP(vr_count)
			lg.log_id,
			lg.user_id,
			un.username,
			un.first_name,
			un.last_name,
			lg.host_address,
			lg.host_name,
			lg.action,
			lg.date,
			lg.info,
			lg.module_identifier
		FROM vr_user_ids AS usr
			INNER JOIN lg_logs AS lg
			ON (vr_application_id IS NULL OR lg.application_id = vr_application_id) AND
				lg.user_id = usr.value
			LEFT JOIN usr_view_users AS un
			ON un.user_id = lg.user_id
		WHERE (vr_last_id IS NULL OR LogID > vr_last_id) AND
			(vr_finish_date IS NULL OR lg.date < vr_finish_date) AND
			(vr_beginDate IS NULL OR lg.date > vr_beginDate) AND
			(vr_actionsCount = 0 OR lg.action IN (SELECT * FROM vr_actions))
		ORDER BY lg.log_id DESC
	END
END;


DROP PROCEDURE IF EXISTS lg_get_logs;

CREATE PROCEDURE lg_get_logs
	vr_application_id	UUID,
    vr_strUserIDs 	varchar(max),
    vr_strActions		varchar(max),
    vr_delimiter		char,
    vr_beginDate	 TIMESTAMP,
    vr_finish_date	 TIMESTAMP,
    vr_last_id			bigint,
    vr_count		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	INSERT INTO vr_user_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_actions StringTableType
	INSERT INTO vr_actions
	SELECT ref.value FROM gfn_str_to_string_table(vr_strActions, vr_delimiter) AS ref
	
	EXEC lg_p_get_logs vr_application_id, vr_user_ids, 
		vr_actions, vr_beginDate, vr_finish_date, vr_last_id, vr_count
END;


DROP PROCEDURE IF EXISTS lg_save_error_log;

CREATE PROCEDURE lg_save_error_log
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_subject			varchar(1000),
	vr_description	 VARCHAR(2000),
	vr_date			 TIMESTAMP,
	vr_module_identifier	varchar(20),
	vr_level				varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO lg_error_logs(
		ApplicationID,
		UserID,
		subject,
		description,
		date,
		ModuleIdentifier,
		level
	)
	VALUES (
		vr_application_id,
		vr_user_id, 
		vr_subject, 
		vr_description, 
		vr_date, 
		vr_module_identifier,
		vr_level
	)
	
	SELECT @vr_rowcount
END;

DROP PROCEDURE IF EXISTS msg_get_threads;

CREATE PROCEDURE msg_get_threads
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_count		 INTEGER,
    vr_last_id		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(COALESCE(vr_count, 10))
		d.thread_id, 
		un.username, 
		un.first_name, 
		un.last_name,
		CAST((CASE WHEN un.user_id IS NULL THEN 1 ELSE 0 END) AS boolean) AS is_group,
		d.messages_count,
		d.sent_count,
		d.not_seen_count,
		d.row_number
	FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY ref.max_id DESC) AS row_number, ref.*
			FROM (
					SELECT md.thread_id, MAX(md.id) AS max_id,
						COUNT(md.id) AS messages_count, 
						SUM(CAST(md.is_sender AS integer)) AS sent_count,
						SUM(
							CAST((CASE WHEN md.is_sender = FALSE AND md.seen = 0 THEN 1 ELSE 0 END) AS integer)
						) AS not_seen_count
					FROM msg_message_details AS md
					WHERE md.application_id = vr_application_id AND 
						md.user_id = vr_user_id AND md.deleted = FALSE
					GROUP BY md.thread_id
				) AS ref
		) AS d
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.thread_id
	WHERE (vr_last_id IS NULL OR d.row_number > vr_last_id)
	ORDER BY d.row_number ASC
END;


DROP PROCEDURE IF EXISTS msg_get_thread_info;

CREATE PROCEDURE msg_get_thread_info
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_thread_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	COUNT(md.id) AS messages_count, 
			SUM(CAST(md.is_sender AS integer)) AS sent_count,
			SUM(
				CAST((CASE WHEN md.is_sender = FALSE AND md.seen = 0 THEN 1 ELSE 0 END) AS integer)
			) AS not_seen_count
	FROM msg_message_details AS md
	WHERE md.application_id = vr_application_id AND 
		md.user_id = vr_user_id AND md.thread_id = vr_thread_id AND md.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS msg_get_messages;

CREATE PROCEDURE msg_get_messages
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_sent		 BOOLEAN,
    vr_count		 INTEGER,
    vr_min_id			BIGINT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	--vr_sent IS NULL --> Sent and Received Messages
	--vr_sent IS NOT NULL --> vr_sent = 1 --> Sent Messages
	--                  --> vr_sent = 0 --> Received Messages
	
	SELECT 
		m.message_id,
		m.title,
		m.message_text,
		m.send_date,
		m.sender_user_id,
		m.forwarded_from,
		d.id,
		d.is_group,
		d.is_sender,
		d.seen,
		d.thread_id,
		un.username,
		un.first_name,
		un.last_name,
		m.has_attachment
	FROM (
			SELECT TOP(COALESCE(vr_count, 20)) *
			FROM msg_message_details AS md
			WHERE md.application_id = vr_application_id AND
				(vr_min_id IS NULL OR  md.id < vr_min_id) AND 
				md.user_id = vr_user_id AND
				(md.thread_id IS NULL OR ThreadID = vr_thread_id) AND 
				(vr_sent IS NULL OR IsSender = vr_sent) AND 
				md.deleted = FALSE
			ORDER BY md.id DESC
		)AS D
		INNER JOIN msg_messages AS m
		ON m.application_id = vr_application_id AND m.message_id = d.message_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = m.sender_user_id
	ORDER BY d.id ASC
END;


DROP PROCEDURE IF EXISTS msg_has_message;

CREATE PROCEDURE msg_has_message
	vr_application_id	UUID,
	vr_iD				BIGINT,
    vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_messageID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		CASE
			WHEN EXISTS(
				SELECT TOP(1) ID
				FROM msg_message_details
				WHERE ApplicationID = vr_application_id AND (vr_iD IS NULL OR ID = vr_iD) AND
					UserID = vr_user_id AND 
					(vr_thread_id IS NULL OR ThreadID = vr_thread_id) AND
					(vr_messageID IS NULL OR MessageID = vr_messageID)
			) THEN 1
			ELSE 0
		END
END;


DROP PROCEDURE IF EXISTS msg_send_new_message;

CREATE PROCEDURE msg_send_new_message
	vr_application_id		UUID,
    vr_user_id				UUID,
    vr_thread_id			UUID,
    vr_messageID			UUID,
    vr_forwarded_from		UUID,
    vr_title			 VARCHAR(500),
    vr_messageText	 VARCHAR(MAX),
    vr_isGroup		 BOOLEAN,
    vr_now			 TIMESTAMP,
    vr_receivers_temp		GuidTableType readonly,
    vr_attachedFilesTemp	DocFileInfoTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_receivers GuidTableType
	INSERT INTO vr_receivers SELECT * FROM vr_receivers_temp
    
    DECLARE vr_attachedFiles DocFileInfoTableType
    INSERT INTO vr_attachedFiles SELECT * FROM vr_attachedFilesTemp
	
	IF vr_isGroup IS NULL SET vr_isGroup = 0
	
	IF vr_thread_id IS NOT NULL BEGIN
		SET vr_isGroup = COALESCE(
			(
				SELECT TOP(1) md.is_group
				FROM msg_message_details AS md
				WHERE md.application_id = vr_application_id AND md.thread_id = vr_thread_id
			), vr_isGroup
		)
	END
	
	DECLARE vr_receiver_user_ids GuidTableType
	
	INSERT INTO vr_receiver_user_ids SELECT * FROM vr_receivers
	
	DECLARE vr_count INTEGER = (SELECT COUNT(*) FROM vr_receiver_user_ids)
	
	IF vr_count = 1 SET vr_isGroup = 0
	
	IF(vr_count > 1) DELETE FROM vr_receiver_user_ids WHERE Value = vr_user_id --Farzane Added
	
	IF (vr_thread_id IS NULL AND vr_isGroup = 0) AND vr_count = 0 BEGIN
		SELECT -1
		RETURN
	END
	
	IF vr_thread_id IS NOT NULL AND vr_count = 0 AND 
		EXISTS(
			SELECT TOP(1) UserID 
			FROM users_normal 
			WHERE ApplicationID = vr_application_id AND UserID = vr_thread_id
	) BEGIN
		INSERT INTO vr_receiver_user_ids (Value)
		VALUES (vr_thread_id)
		
		SET vr_count = 1
	END
	
	IF vr_isGroup = 1 BEGIN
		IF vr_count = 1 SET vr_thread_id = (SELECT TOP(1) ref.value FROM vr_receiver_user_ids AS ref)
		ELSE IF (vr_thread_id IS NULL AND vr_count > 0) SET vr_thread_id = gen_random_uuid()
	END
	
	IF vr_count = 0 BEGIN
		INSERT INTO vr_receiver_user_ids
		SELECT DISTINCT md.user_id 
		FROM msg_message_details AS md
		WHERE md.application_id = vr_application_id AND md.thread_id = vr_thread_id
		EXCEPT (SELECT vr_user_id)
		
		SET vr_count = (SELECT COUNT(*) FROM vr_receiver_user_ids)
	END
	
	DECLARE vr_attachmentsCount INTEGER = (SELECT COUNT(*) FROM vr_attachedFiles)
	
	INSERT INTO msg_messages(
		ApplicationID,
		MessageID,
		Title,
		MessageText,
		SenderUserID,
		SendDate,
		ForwardedFrom,
		HasAttachment
	)
	VALUES(
		vr_application_id,
		vr_messageID,
		vr_title,
		vr_messageText,
		vr_user_id,
		vr_now,
		vr_forwarded_from,
		CASE WHEN vr_attachmentsCount > 0 THEN 1 ELSE 0 END
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE vr__result INTEGER
	
	IF vr_attachmentsCount > 0 BEGIN
		EXEC dct_p_add_files vr_application_id, vr_messageID, 
			N'Message', vr_attachedFiles, vr_user_id, vr_now, vr__result output
		
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF vr_forwarded_from IS NOT NULL BEGIN
		EXEC dct_p_copy_attachments vr_application_id, vr_forwarded_from, 
			vr_messageID, N'Message', vr_user_id, vr_now, vr__result output
		
		IF vr__result > 0 BEGIN
			UPDATE msg_messages
				SET HasAttachment = 1
			WHERE ApplicationID = vr_application_id AND MessageID = vr_messageID
		END 
	END
	
	INSERT INTO msg_message_details(
		ApplicationID,
		UserID,
		ThreadID,
		MessageID,
		Seen,
		IsSender,
		IsGroup,
		Deleted
	)
	(
		SELECT	TOP(CASE WHEN vr_isGroup = 1 THEN 1 ELSE 1000000000 END)
				vr_application_id,
				vr_user_id,
				CASE WHEN vr_isGroup = 0 THEN r.value ELSE vr_thread_id END,
				vr_messageID,
				1,
				1,
				vr_isGroup,
				0
		FROM vr_receiver_user_ids AS r
		
		UNION ALL
		
		SELECT	vr_application_id,
				r.value,
				CASE WHEN vr_isGroup = 0 THEN vr_user_id ELSE vr_thread_id END,
				vr_messageID,
				0,
				0,
				vr_isGroup,
				0
		FROM vr_receiver_user_ids AS r
	)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT @vr_iDENTITY - vr_count
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS msg_bulk_send_message;

CREATE PROCEDURE msg_bulk_send_message
	vr_application_id	UUID,
    vr_messagesTemp	MessageTableType readonly,
    vr_receivers_temp	GuidPairTableType readonly,
    vr_now		 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE vr_messages MessageTableType
	INSERT INTO vr_messages SELECT * FROM vr_messagesTemp
    
    DECLARE vr_receivers GuidPairTableType
    INSERT INTO vr_receivers SELECT * FROM vr_receivers_temp
	
	INSERT INTO msg_messages(
		ApplicationID,
		MessageID,
		Title,
		MessageText,
		SenderUserID,
		SendDate,
		HasAttachment
	)
	SELECT	vr_application_id,
			m.message_id,
			m.title,
			m.message_text,
			m.sender_user_id,
			vr_now,
			0
	FROM vr_messages AS m
	WHERE m.message_id IN (SELECT DISTINCT r.first_value FROM vr_receivers AS r)
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	INSERT INTO msg_message_details(
		ApplicationID,
		UserID,
		ThreadID,
		MessageID,
		Seen,
		IsSender,
		IsGroup,
		Deleted
	)
	SELECT *
	FROM (
			SELECT	vr_application_id AS application_id,
					m.sender_user_id,
					r.second_value,
					m.message_id,
					1 AS seen,
					1 AS is_sender,
					0 AS is_group,
					0 AS deleted
			FROM vr_messages AS m
				INNER JOIN vr_receivers AS r
				ON r.first_value = m.message_id
			
			UNION ALL
			
			SELECT	vr_application_id,
					r.second_value,
					m.sender_user_id,
					m.message_id,
					0,
					0,
					0,
					0
			FROM vr_messages AS m
				INNER JOIN vr_receivers AS r
				ON r.first_value = m.message_id
		) AS ref
	ORDER BY ref.is_sender DESC
	
	IF @vr_rowcount <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT @vr_iDENTITY
COMMIT TRANSACTION;


DROP PROCEDURE IF EXISTS msg_get_thread_users;

CREATE PROCEDURE msg_get_thread_users
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_strThreadIDs	VARCHAR(MAX),
    vr_delimiter		CHAR,
	vr_count		 INTEGER,
	vr_last_id		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_thread_ids GuidTableType

	INSERT INTO vr_thread_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strThreadIDs, vr_delimiter) AS ref
	
	DECLARE vr_messageIDs GuidPairTableType

	;WITH X AS (
		SELECT md.thread_id, MIN(md.id) AS min_id
		FROM vr_thread_ids AS t
			INNER JOIN msg_message_details AS md
			ON md.application_id = vr_application_id AND md.thread_id = t.value
		GROUP BY md.thread_id
	)
	INSERT INTO vr_messageIDs(FirstValue, SecondValue)
	SELECT md.thread_id, md.message_id
	FROM X
		INNER JOIN msg_message_details AS md
		ON md.application_id = vr_application_id AND md.id = x.min_id

	;WITH Y AS (
		SELECT *
		FROM (
				SELECT  ROW_NUMBER() OVER (PARTITION BY md.thread_id ORDER BY md.id DESC) AS row_number, 
						ROW_NUMBER() OVER (PARTITION BY md.thread_id ORDER BY md.id ASC) AS rev_row_number,
						md.thread_id, md.user_id
				FROM vr_messageIDs AS m
					INNER JOIN msg_message_details AS md
					ON md.thread_id = m.first_value AND md.message_id = m.second_value
				WHERE md.application_id = vr_application_id AND md.user_id NOT IN (SELECT vr_user_id)
			) AS ref
		WHERE ref.row_number > COALESCE(vr_last_id, 0) AND ref.row_number <= (COALESCE(vr_last_id, 0) + COALESCE(vr_count, 3))
	)
	SELECT	y.thread_id, 
			y.user_id, 
			un.username, 
			un.first_name, 
			un.last_name,
			y.rev_row_number
	FROM Y
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = y.user_id
END;


DROP PROCEDURE IF EXISTS msg_remove_messages;

CREATE PROCEDURE msg_remove_messages
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_iD				BIGINT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE msg_message_details
		SET deleted = TRUE
	WHERE ApplicationID = vr_application_id AND (vr_iD IS NOT NULL AND ID = vr_iD) OR  
		(vr_iD IS NULL AND UserID = vr_user_id AND ThreadID = vr_thread_id)
		
		
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS msg_set_messages_as_seen;

CREATE PROCEDURE msg_set_messages_as_seen
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF vr_user_id IS NOT NULL AND vr_thread_id IS NOT NULL BEGIN
		UPDATE MD
			SET Seen = 1,
				ViewDate = COALESCE(ViewDate, vr_now)
		FROM msg_message_details AS md
		WHERE md.application_id = vr_application_id AND
			md.user_id = vr_user_id AND md.thread_id = vr_thread_id AND ViewDate IS NULL
		
		SELECT 1
	END
	ELSE SELECT 0
END;


DROP PROCEDURE IF EXISTS msg_get_not_seen_messages_count;

CREATE PROCEDURE msg_get_not_seen_messages_count
	vr_application_id	UUID,
    vr_user_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT COUNT(md.id)
	FROM msg_message_details AS md
	WHERE md.application_id = vr_application_id AND
		md.user_id = vr_user_id AND md.is_sender = FALSE AND md.seen = 0 AND md.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS msg_get_message_receivers;

CREATE PROCEDURE msg_get_message_receivers
	vr_application_id	UUID,
    vr_strMessageIDs VARCHAR(MAX),
    vr_delimiter		CHAR,
	vr_count		 INTEGER,
	vr_last_id		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_messageIDs GuidTableType

	INSERT INTO vr_messageIDs
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strMessageIDs, vr_delimiter) AS ref
	
	;WITH Y AS (
		SELECT *
		FROM (
				SELECT  ROW_NUMBER() OVER (PARTITION BY md.message_id ORDER BY md.id DESC) AS row_number, 
						ROW_NUMBER() OVER (PARTITION BY md.message_id ORDER BY md.id ASC) AS rev_row_number,
						md.message_id, md.user_id
				FROM vr_messageIDs AS r
					INNER JOIN msg_message_details AS md
					ON md.message_id = r.value
				WHERE md.application_id = vr_application_id AND md.is_sender = FALSE
			) AS ref
		WHERE ref.row_number > COALESCE(vr_last_id, 0) AND ref.row_number <= (COALESCE(vr_last_id, 0) + COALESCE(vr_count, 3))
	)
	SELECT	y.message_id, 
			y.user_id, 
			un.username, 
			un.first_name, 
			un.last_name,
			y.rev_row_number
	FROM Y
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = y.user_id
END;


DROP PROCEDURE IF EXISTS msg_get_forwarded_messages;

CREATE PROCEDURE msg_get_forwarded_messages
	vr_application_id	UUID,
	vr_messageID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_hierarchy_messages AS table (
		MessageID UUID,
		IsGroup BOOLEAN,
		ForwardedFrom UUID,
		level INTEGER
	)
	
	;WITH hierarchy (MessageID, ForwardedFrom, level)
 AS 
	(
		SELECT m.message_id AS message_id, ForwardedFrom, 0 AS level
		FROM msg_messages AS m
		WHERE m.application_id = vr_application_id AND MessageID = vr_messageID
		
		UNION ALL
		
		SELECT m.message_id AS message_id, m.forwarded_from , level + 1
		FROM msg_messages AS m
			INNER JOIN hierarchy AS hr
			ON m.message_id = hr.forwarded_from
		WHERE m.application_id = vr_application_id AND m.message_id <> hr.message_id
	)
	INSERT INTO vr_hierarchy_messages(
		MessageID, 
		IsGroup, 
		ForwardedFrom, 
		level
	)
	SELECT 
		ref.message_id AS message_id, 
		md.is_group, 
		ref.forwarded_from,
		ref.level
	FROM (
			SELECT hm.message_id, hm.forwarded_from, hm.level , MAX(md.id) AS id
			FROM hierarchy AS hm
				INNER JOIN msg_message_details AS md
				ON md.application_id = vr_application_id AND md.message_id = hm.message_id
			GROUP BY hm.message_id, hm.forwarded_from, hm.level
		) AS ref
		INNER JOIN msg_message_details AS md
		ON md.application_id = vr_application_id AND md.id = ref.id
	
	SELECT 
		m.message_id,
		m.message_text,
		m.title,
		m.send_date,
		m.has_attachment,
		h.forwarded_from,
		h.level,
		h.is_group,
		m.sender_user_id,
		un.username AS sender_username,
		un.first_name AS sender_first_name,
		un.last_name AS sender_last_name
	FROM vr_hierarchy_messages AS h
		INNER JOIN msg_messages AS m
		ON m.application_id = vr_application_id AND m.message_id = h.message_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = m.sender_user_id
	ORDER BY h.level ASC
END;



DROP PROCEDURE IF EXISTS rv_overal_report;

CREATE PROCEDURE rv_overal_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_beginDate	 TIMESTAMP,
	vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT N'تعداد کاربران' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND 
		(vr_beginDate IS NULL OR ref.creation_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR ref.creation_date <= vr_finish_date) AND ref.is_approved = TRUE
			
	UNION ALL
	
	SELECT N'تعداد کاربران با پروفایل تکمیل شده' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND
		ref.first_name IS NOT NULL AND ref.first_name <> N'' AND
		ref.last_name IS NOT NULL AND ref.last_name <> N'' AND
		(vr_beginDate IS NULL OR ref.creation_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR ref.creation_date <= vr_finish_date) AND ref.is_approved = TRUE
			
	UNION ALL
	
	SELECT N'تعداد کاربران فعال' + ' (' + N'15 روزه' + N')' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND
		ref.last_activity_date >= DATEADD(DAY, -15, GETDATE()) AND ref.is_approved = TRUE
			
	UNION ALL
	
	SELECT N'تعداد کاربران فعال' + ' (' + N'30 روزه' + N')' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND
		ref.last_activity_date >= DATEADD(DAY, -30, GETDATE()) AND ref.is_approved = TRUE

	UNION ALL

	SELECT N'تعداد پرسش ها', COUNT(QuestionID)
	FROM qa_questions
	WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
		(vr_beginDate IS NULL OR SendDate >= vr_beginDate) AND
		(vr_finish_date IS NULL OR SendDate <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد پرسش های دارای بهترین پاسخ', COUNT(QuestionID)
	FROM qa_questions
	WHERE ApplicationID = vr_application_id AND status = N'Accepted' AND 
		PublicationDate IS NOT NULL AND deleted = FALSE AND 
		(vr_beginDate IS NULL OR SendDate >= vr_beginDate) AND
		(vr_finish_date IS NULL OR SendDate <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد خبره های تعریف شده' + ' (' + N'کل خبره ها' + N')', COUNT(ex.user_id) 
	FROM cn_experts AS ex
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ex.user_id
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
	WHERE ex.application_id = vr_application_id AND 
		(ex.approved = TRUE OR ex.social_approved = TRUE) AND
		un.is_approved = TRUE AND nd.deleted = FALSE
		
		
	UNION ALL

	SELECT N'تعداد کاربران خبره' + N' (' + N'کل خبره ها' + N')', COUNT(CNT)
	FROM (
			SELECT COUNT(un.user_id) AS cnt
			FROM cn_experts AS ex
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ex.user_id
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
			WHERE ex.application_id = vr_application_id AND 
				(ex.approved = TRUE OR ex.social_approved = TRUE) AND
				un.is_approved = TRUE AND nd.deleted = FALSE
			GROUP BY un.user_id
		) AS ref
	
	UNION ALL

	SELECT N'تعداد لایک های پست ها', COUNT(sl.share_id)
	FROM sh_share_likes AS sl
	WHERE sl.application_id = vr_application_id AND sl.like = TRUE AND
		(vr_beginDate IS NULL OR sl.date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR sl.date <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد لایک های کامنت ها', COUNT(sl.comment_id)
	FROM sh_comment_likes AS sl
	WHERE sl.application_id = vr_application_id AND sl.like = TRUE AND
		(vr_beginDate IS NULL OR sl.date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR sl.date <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد لایک های صفحات', COUNT(nl.node_id)
	FROM cn_node_likes AS nl
	WHERE nl.application_id = vr_application_id AND nl.deleted = FALSE AND
		(vr_beginDate IS NULL OR nl.like_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR nl.like_date <= vr_finish_date)
			
	UNION ALL

	SELECT N'تعداد پست ها', COUNT(ps.share_id)
	FROM sh_post_shares AS ps
	WHERE ps.application_id = vr_application_id AND ps.deleted = FALSE AND
		(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date)
	
	UNION ALL

	SELECT N'تعداد کامنت ها', COUNT(c.comment_id)
	FROM sh_comments AS c
	WHERE c.application_id = vr_application_id AND c.deleted = FALSE AND
		(vr_beginDate IS NULL OR c.send_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR c.send_date <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد دانش ها', COUNT(KnowledgeID)
	FROM kw_view_knowledges
	WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
		(vr_beginDate IS NULL OR CreationDate >= vr_beginDate) AND
		(vr_finish_date IS NULL OR CreationDate <= vr_finish_date)

	UNION ALL

	SELECT N'تعداد دانش های تایید شده', COUNT(KnowledgeID)
	FROM kw_view_knowledges
	WHERE ApplicationID = vr_application_id AND 
		status = N'Accepted' AND deleted = FALSE AND
		(vr_beginDate IS NULL OR COALESCE(PublicationDate, CreationDate) >= vr_beginDate) AND
		(vr_finish_date IS NULL OR COALESCE(PublicationDate, CreationDate) <= vr_finish_date)
			
	UNION ALL
	
	SELECT x.item_name, x.count
	FROM (
			SELECT TOP(1000000) a.item_name, a.count
			FROM (
					SELECT	(N'تعداد ' + nt.name + (CASE WHEN ref.type = N'Count' THEN N'' ELSE N' - منتشر شده' END)) AS item_name, 
							COALESCE(ref.count, 0) AS count,
							COALESCE(ref.total_count, 0) AS total_count
					FROM (
							SELECT	NodeTypeID, 
									COUNT(NodeID) AS count, 
									COUNT(NodeID) AS total_count, 
									N'Count' AS type
							FROM cn_view_nodes_normal
							WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
								(vr_beginDate IS NULL OR CreationDate >= vr_beginDate) AND
								(vr_finish_date IS NULL OR CreationDate <= vr_finish_date)
							GROUP BY NodeTypeID
							
							UNION ALL
							
							SELECT	NodeTypeID, 
									SUM(CAST((CASE WHEN ISNULL.searchable, TRUE = 1 THEN 1 ELSE 0 END) AS integer)) AS count,
									COUNT(NodeID) AS total_count,
									N'Published' AS type
							FROM cn_view_nodes_normal
							WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
								(vr_beginDate IS NULL OR CreationDate >= vr_beginDate) AND
								(vr_finish_date IS NULL OR CreationDate <= vr_finish_date)
							GROUP BY NodeTypeID
						) AS ref
						RIGHT JOIN cn_node_types AS nt
						ON nt.application_id = vr_application_id AND nt.node_type_id = ref.node_type_id
					WHERE nt.application_id = vr_application_id AND nt.deleted = FALSE
				) AS a
			ORDER BY a.total_count DESC, a.item_name ASC
		) AS x
END;


DROP PROCEDURE IF EXISTS rv_logs_report;

CREATE PROCEDURE rv_logs_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_user_id				UUID,
	vr_actionsTemp		StringTableType readonly,
	vr_iPAddressesTemp	StringTableType readonly,
	vr_level				varchar(20),
	vr_not_authorized	 BOOLEAN,
	vr_anonymous		 BOOLEAN,
	vr_beginDate		 TIMESTAMP,
	vr_finish_date		 TIMESTAMP,
	vr_count			 INTEGER,
	vr_lower_boundary		bigint
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_actions StringTableType
	INSERT INTO vr_actions SELECT * FROM vr_actionsTemp
	
	DECLARE vr_actionExists BOOLEAN = CASE WHEN EXISTS(SELECT TOP(1) * FROM vr_actions) THEN 1 ELSE 0 END
	
	DECLARE vr_iPAddresses StringTableType
	INSERT INTO vr_iPAddresses SELECT * FROM vr_iPAddressesTemp
	
	DECLARE vr_iPExists BOOLEAN = CASE WHEN EXISTS(SELECT TOP(1) * FROM vr_iPAddresses) THEN 1 ELSE 0 END
	
	IF vr_not_authorized IS NULL SET vr_not_authorized = 0
	IF vr_level = N'' SET vr_level = NULL
	
	DECLARE vr_empty UUID = N'00000000-0000-0000-0000-000000000000'
	
	SET vr_anonymous = COALESCE(vr_anonymous, 0)
	IF vr_anonymous = 1 SET vr_user_id = NULL
	
	SELECT TOP(COALESCE(vr_count, 2000))
		(ref.row_number_hide + ref.rev_row_number_hide - 1) AS total_count_hide,
		ref.*
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY lg.log_id DESC) AS row_number_hide,
					ROW_NUMBER() OVER (ORDER BY lg.log_id ASC) AS rev_row_number_hide,
					lg.log_id AS log_id_hide,
					un.user_id AS user_id_hide,
					RTRIM(LTRIM(COALESCE(un.first_name, N'') + N' ' + 
						COALESCE(un.last_name, N''))) AS full_name,
					lg.action AS action_dic,
					lg.level AS level_dic,
					CASE 
						WHEN COALESCE(lg.not_authorized, FALSE) = 0 THEN N'' 
						ELSE N'بله' 
					END AS not_authorized,
					lg.date,
					lg.host_address,
					lg.host_name,
					CASE 
						WHEN lg.subject_id = vr_empty THEN NULL 
						ELSE lg.subject_id
					END AS subject_id,
					del_first.object_type AS first_type_hide,
					lg.second_subject_id,
					del_second.object_type AS second_type_hide,
					lg.third_subject_id,
					del_third.object_type AS third_type_hide,
					lg.fourth_subject_id,
					del_fourth.object_type AS fourth_type_hide,
					lg.info AS info_hide_c
			FROM lg_logs AS lg
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = lg.user_id
				LEFT JOIN rv_deleted_states AS del_first
				ON del_first.application_id = vr_application_id AND
					del_first.object_id = lg.subject_id
				LEFT JOIN rv_deleted_states AS del_second
				ON del_second.application_id = vr_application_id AND
					del_second.object_id = lg.second_subject_id
				LEFT JOIN rv_deleted_states AS del_third
				ON del_third.application_id = vr_application_id AND
					del_third.object_id = lg.third_subject_id
				LEFT JOIN rv_deleted_states AS del_fourth
				ON del_fourth.application_id = vr_application_id AND
					del_fourth.object_id = lg.fourth_subject_id
			WHERE lg.application_id = vr_application_id AND 
				(vr_user_id IS NULL OR lg.user_id = vr_user_id) AND
				(vr_anonymous = 0 OR lg.user_id = vr_empty) AND
				(vr_actionExists = 0 OR lg.action IN (SELECT * FROM vr_actions)) AND
				(vr_iPExists = 0 OR lg.host_address IN (SELECT * FROM vr_iPAddresses)) AND
				(vr_level IS NULL OR lg.level = vr_level) AND
				(vr_beginDate IS NULL OR lg.date >= vr_beginDate) AND
				(vr_finish_date IS NULL OR lg.date <= vr_finish_date) AND
				(vr_not_authorized = 0 OR lg.not_authorized = TRUE)
		) AS ref
	WHERE ref.row_number_hide >= COALESCE(vr_lower_boundary, 0)
	ORDER BY ref.row_number_hide ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Action_Dic": {"Action": "JSON", "Shows": "Info_HideC"},' +
			'"SubjectID": {"Action": "Link", "Type": "[first_type_hide]",' +
				'"Requires": {"ID": "SubjectID"}' +
			'},' +
			'"SecondSubjectID": {"Action": "Link", "Type": "[second_type_hide]",' +
				'"Requires": {"ID": "SecondSubjectID"}' +
			'},' +
			'"ThirdSubjectID": {"Action": "Link", "Type": "[third_type_hide]",' +
				'"Requires": {"ID": "ThirdSubjectID"}' +
			'},' +
			'"FourthSubjectID": {"Action": "Link", "Type": "[fourth_type_hide]",' +
				'"Requires": {"ID": "FourthSubjectID"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_error_logs_report;

CREATE PROCEDURE rv_error_logs_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_level			varchar(20),
	vr_beginDate	 TIMESTAMP,
	vr_finish_date	 TIMESTAMP,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_level = N'' SET vr_level = NULL
	
	SELECT TOP(COALESCE(vr_count, 2000))
		(ref.row_number_hide + ref.rev_row_number_hide - 1) AS total_count_hide,
		ref.*
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY lg.log_id DESC) AS row_number_hide,
					ROW_NUMBER() OVER (ORDER BY lg.log_id ASC) AS rev_row_number_hide,
					lg.log_id AS log_id_hide,
					lg.subject,
					lg.level AS level_dic,
					lg.description AS description_hide_c,
					lg.date
			FROM lg_error_logs AS lg
			WHERE lg.application_id = vr_application_id AND 
				(vr_level IS NULL OR lg.level = vr_level) AND
				(vr_beginDate IS NULL OR lg.date >= vr_beginDate) AND
				(vr_finish_date IS NULL OR lg.date <= vr_finish_date)
		) AS ref
	WHERE ref.row_number_hide >= COALESCE(vr_lower_boundary, 0)
	ORDER BY ref.row_number_hide ASC
	
	SELECT ('{' +
			'"Subject": {"Action": "Show", "Shows": "Description_HideC"}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_knowledge_supply_indicators_report;

CREATE PROCEDURE rv_knowledge_supply_indicators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_creatorNodeIDs GuidTableType

	INSERT INTO vr_creatorNodeIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref

	DECLARE vr_creatorCount INTEGER = (SELECT COUNT(*) FROM vr_creatorNodeIDs)

	SELECT	r.group_id AS group_id_hide,
			MAX(n.name) AS group_name,
			COUNT(DISTINCT nm.user_id) AS members_count,
			MAX(r.contents_count) AS contents_count,
			MAX(r.average_collaboration_share) AS average_collaboration_share,
			MAX(r.accepted_count) AS accepted_count,
			MAX(r.average_accepted_score) AS average_accepted_score,
			MAX(r.published_count) AS published_count,
			MAX(r.answers_count) AS answers_count,
			MAX(r.wiki_changes_count) AS wiki_changes_count
	FROM (
			SELECT groups.node_id AS group_id, 
				COUNT(contents.node_id) AS contents_count,
				SUM(nc.collaboration_share) / COUNT(contents.node_id) AS average_collaboration_share,
				SUM(CASE WHEN contents.status = N'Accepted' THEN 1 ELSE 0 END) AS accepted_count,
				SUM(
					CASE 
						WHEN contents.status = N'Accepted' THEN COALESCE(contents.score, 0) 
						ELSE 0 
					END
				) / COUNT(contents.node_id) AS average_accepted_score,
				SUM(CASE WHEN contents.searchable = TRUE THEN 1 ElSE 0 END) AS published_count,
				0 AS answers_count,
				0 AS wiki_changes_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.user_id = nm.user_id
				INNER JOIN cn_nodes AS contents
				ON contents.application_id = vr_application_id AND contents.node_id = nc.node_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND
				nc.deleted = FALSE AND contents.node_type_id = vr_nodeTypeID AND 
				(vr_lower_creation_date_limit IS NULL OR contents.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR contents.creation_date <= vr_upper_creation_date_limit) AND
				contents.deleted = FALSE
			GROUP BY groups.node_id

			UNION ALL

			SELECT groups.node_id AS group_id,
				0 AS contents_count,
				0 AS average_collaboration_share,
				0 AS accepted_count,
				0 AS average_accepted_score,
				0 AS published_count,
				COUNT(a.answer_id) AS answers_count,
				0 AS wiki_changes_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN qa_answers AS a
				ON a.application_id = vr_application_id AND a.sender_user_id = nm.user_id
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = a.question_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND a.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR a.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR a.send_date <= vr_upper_creation_date_limit) AND
				q.deleted = FALSE
			GROUP BY groups.node_id

			UNION ALL

			SELECT x.group_id, 
				0 AS contents_count,
				0 AS average_collaboration_share,
				0 AS accepted_count,
				0 AS average_accepted_score,
				0 AS published_count,
				0 AS answers_count,
				COUNT(x.paragraph_id) AS wiki_changes_count
			FROM (
					SELECT DISTINCT groups.node_id AS group_id, nm.user_id, p.paragraph_id
					FROM cn_nodes AS groups
						INNER JOIN cn_view_node_members AS nm
						ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
							nm.is_pending = FALSE
						INNER JOIN wk_changes AS c
						ON c.application_id = vr_application_id AND c.user_id = nm.user_id
						INNER JOIN wk_paragraphs AS p
						ON p.application_id = vr_application_id AND p.paragraph_id = c.paragraph_id
						INNER JOIN wk_titles AS t
						ON t.application_id = vr_application_id AND t.title_id = p.title_id
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = t.owner_id
					WHERE groups.application_id = vr_application_id AND (
							(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
							(vr_creatorCount = 0 AND
								(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
							)
						) AND groups.deleted = FALSE AND
						(vr_lower_creation_date_limit IS NULL OR c.send_date >= vr_lower_creation_date_limit) AND
						(vr_upper_creation_date_limit IS NULL OR c.send_date <= vr_upper_creation_date_limit) AND
						(c.status = N'Accepted' OR c.applied = 1) AND c.deleted = FALSE AND p.deleted = FALSE AND
						(p.status = N'Accepted' OR p.status = N'CitationNeeded') AND
						t.deleted = FALSE AND nd.deleted = FALSE AND (nd.searchable = TRUE OR nd.status = N'Accepted')
				) AS x
			GROUP BY x.group_id
		) AS r
		INNER JOIN cn_nodes AS n
		ON n.application_id = vr_application_id AND n.node_id = r.group_id
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n.node_id AND nm.is_pending = FALSE
	GROUP BY r.group_id

	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'}' +
	   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_knowledge_demand_indicators_report;

CREATE PROCEDURE rv_knowledge_demand_indicators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_creatorNodeIDs GuidTableType

	INSERT INTO vr_creatorNodeIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref

	DECLARE vr_creatorCount INTEGER = (SELECT COUNT(*) FROM vr_creatorNodeIDs)

	SELECT	r.group_id AS group_id_hide,
			MAX(n.name) AS group_name,
			COUNT(DISTINCT nm.user_id) AS members_count,
			MAX(r.searches_count) AS searches_count,
			MAX(r.questions_count) AS questions_count,
			MAX(r.content_visits_count) AS content_visits_count,
			MAX(r.distinct_content_visits_count) AS distinct_content_visits_count,
			MAX(r.posts_count) AS posts_count,
			MAX(r.comments_count) AS comments_count
	FROM (
			SELECT	groups.node_id AS group_id,
					COUNT(l.log_id) AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN lg_logs AS l
				ON l.application_id = vr_application_id AND l.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND l.action = N'Search' AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR l.date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR l.date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					COUNT(q.question_id) AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.sender_user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND q.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR q.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR q.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					COUNT(iv.item_id) AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN usr_item_visits AS iv
				ON nm.application_id = vr_application_id AND iv.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND
				(iv.item_type = N'Node' OR iv.item_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR iv.visit_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR iv.visit_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id
			
			UNION ALL
			
			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					COUNT(DISTINCT iv.item_id) AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN usr_item_visits AS iv
				ON iv.application_id = vr_application_id AND iv.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND 
				(iv.item_type = N'Node' OR iv.item_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR iv.visit_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR iv.visit_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					COUNT(ps.share_id) AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.sender_user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND 
				(ps.owner_type = N'Node' OR ps.owner_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					COUNT(c.comment_id) AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_comments AS c
				ON c.application_id = vr_application_id AND c.sender_user_id = nm.user_id
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.share_id = c.share_id
			WHERE groups.application_id = vr_application_id AND 
				(ps.owner_type = N'Node' OR ps.owner_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND c.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id
		) AS r
		INNER JOIN cn_nodes AS n
		ON n.application_id = vr_application_id AND n.node_id = r.group_id
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n.node_id AND nm.is_pending = FALSE
	GROUP BY r.group_id
	
	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'}' +
	   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_social_contribution_indicators_report;

CREATE PROCEDURE rv_social_contribution_indicators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_creatorNodeIDs GuidTableType

	INSERT INTO vr_creatorNodeIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref

	DECLARE vr_creatorCount INTEGER = (SELECT COUNT(*) FROM vr_creatorNodeIDs)

	SELECT	r.group_id AS group_id_hide,
			MAX(n.name) AS group_name,
			COUNT(DISTINCT nm.user_id) MembersCount,
			MAX(r.active_users_count) AS active_users_count,
			MAX(r.posts_count) AS posts_count,
			MAX(r.comments_count) AS comments_count
	FROM (
			SELECT	groups.node_id AS group_id,
					COUNT(DISTINCT un.user_id) AS active_users_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND un.is_approved = TRUE AND
				(vr_lower_creation_date_limit IS NULL OR un.last_activity_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR un.last_activity_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS active_users_count,
					COUNT(ps.share_id) AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.sender_user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS active_users_count,
					0 AS posts_count,
					COUNT(c.comment_id) AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_comments AS c
				ON c.application_id = vr_application_id AND c.sender_user_id = nm.user_id
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.share_id = c.share_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND c.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id
		) AS r
		INNER JOIN cn_nodes AS n
		ON n.application_id = vr_application_id AND n.node_id = r.group_id
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n.node_id AND nm.is_pending = FALSE
	GROUP BY r.group_id
	
	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'}' +
	   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_applications_performance_report;

CREATE PROCEDURE rv_applications_performance_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_strTeamIDs varchar(max),
	vr_delimiter	char,
	vr_date_from TIMESTAMP,
	vr_dateMiddle TIMESTAMP,
	vr_date_to	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_team_ids GuidTableType

	INSERT INTO vr_team_ids (value)
	SELECT ref.value 
	FROM gfn_str_to_guid_table(vr_strTeamIDs, vr_delimiter) AS ref

	DECLARE vr_teams_count INTEGER = (SELECT COUNT(*) FROM vr_team_ids)
	DECLARE vr_node_ids GuidTableType
	DECLARE vr_archive BOOLEAN = 0

	;WITH Applications
 AS 
	(
		SELECT	app.application_id AS application_id, 
				app.title,
				(
					SELECT COUNT(*)
					FROM usr_user_applications AS u
					WHERE u.application_id = app.application_id
				) AS members_count,
				(
					SELECT COUNT(*)
					FROM cn_node_types AS nt
						LEFT JOIN cn_services AS s
						ON s.application_id = app.application_id AND s.node_type_id = nt.node_type_id
					WHERE nt.application_id = app.application_id AND nt.deleted = FALSE AND COALESCE(s.service_title, N'') <> N''
				) AS templates_count
		FROM rv_applications AS app
		WHERE ((vr_teams_count = 0 AND COALESCE(app.deleted, FALSE) = 0) OR app.application_id IN (SELECT t.value FROM vr_team_ids AS t))
	),
	Nodes
 AS 
	(
		SELECT	app.application_id,
				nd.node_type_id,
				nd.node_id,
				nd.type_name AS node_type, 
				nd.node_name, 
				nd.node_additional_id AS additional_id, 
				nd.creation_date,
				(CASE 
					WHEN nd.creation_date >= vr_date_from AND nd.creation_date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
					WHEN nd.creation_date >= DATEADD(DAY, 1, vr_dateMiddle) AND nd.creation_date < DATEADD(DAY, 1, vr_date_to) THEN 2
					ELSE 0
				END) AS period,
				COALESCE(email.email_address, usr.username) AS creator_username,
				LTRIM(RTRIM(COALESCE(usr.first_name, N'') + N' ' + COALESCE(usr.last_name, N''))) AS creator_full_name
		FROM Applications AS app
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = app.application_id AND 
				(vr_archive IS NULL OR nd.deleted = vr_archive)
			INNER JOIN usr_view_users AS usr
			ON usr.user_id = nd.creator_user_id
			LEFT JOIN usr_email_addresses AS email
			ON email.email_id = usr.main_email_id
	),
	Files
 AS 
	(
		SELECT	nd.application_id, 
				files.file_id,
				files.file_name,
				files.extension,
				files.size,
				files.owner_type,
				files.creation_date,
				files.creator_user_id,
				files.deleted AS file_archived,
				(CASE 
					WHEN files.creation_date >= vr_date_from AND files.creation_date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
					WHEN files.creation_date >= DATEADD(DAY, 1, vr_dateMiddle) AND files.creation_date < DATEADD(DAY, 1, vr_date_to) THEN 2
					ELSE 0
				END) AS period
		FROM Nodes AS nd
			INNER JOIN dct_fn_list_deep_attachments(vr_team_ids, vr_node_ids, vr_archive) AS files
			ON files.application_id = nd.application_id AND files.node_id = nd.node_id
	),
	Visits
 AS 
	(
		SELECT x.application_id, x.period, COUNT(x.unique_id) AS visits_count, COUNT(DISTINCT x.node_id) AS visited_nodes_count
		FROM (
				SELECT	nd.application_id,
						v.unique_id,
						nd.node_id, 
						v.visit_date, 
						(CASE 
							WHEN v.visit_date >= vr_date_from AND v.visit_date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
							WHEN v.visit_date >= DATEADD(DAY, 1, vr_dateMiddle) AND v.visit_date < DATEADD(DAY, 1, vr_date_to) THEN 2
							ELSE 0
						END) AS period
				FROM Nodes AS nd
					INNER JOIN usr_item_visits AS v
					ON v.application_id = nd.application_id AND v.item_id = nd.node_id
			) AS x
		GROUP BY x.application_id, x.period
	),
	Logs
 AS 
	(
		SELECT x.application_id, x.action, x.period, COUNT(x.log_id) AS count
		FROM (
				SELECT	app.application_id,
						lg.log_id, 
						lg.date, 
						lg.action,
						(CASE 
							WHEN lg.date >= vr_date_from AND lg.date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
							WHEN lg.date >= DATEADD(DAY, 1, vr_dateMiddle) AND lg.date < DATEADD(DAY, 1, vr_date_to) THEN 2
							ELSE 0
						END) AS period
				FROM Applications AS app
					INNER JOIN lg_logs AS lg
					ON lg.application_id = app.application_id AND lg.action IN ('Login', 'Search')
			) AS x
		GROUP BY x.application_id, x.action, x.period
	),
	AggregatedNodes
 AS 
	(
		SELECT	app.application_id,
				COALESCE(COUNT(n.node_id), 0) AS created_nodes_count,
				COALESCE(COUNT(CASE WHEN n.period = 1 THEN n.node_id ELSE NULL END), 0) AS created_nodes_count_1,
				COALESCE(COUNT(CASE WHEN n.period = 2 THEN n.node_id ELSE NULL END), 0) AS created_nodes_count_2,
				COALESCE(COUNT(DISTINCT n.node_type_id), 0) AS used_templates_count,
				COALESCE(COUNT(DISTINCT CASE WHEN n.period = 1 THEN n.node_type_id ELSE NULL END), 0) AS used_templates_count_1,
				COALESCE(COUNT(DISTINCT CASE WHEN n.period = 2 THEN n.node_type_id ELSE NULL END), 0) AS used_templates_count_2
		FROM Applications AS app
			INNER JOIN Nodes AS n
			ON n.application_id = app.application_id
		GROUP BY app.application_id
	),
	AggregatedLogin
 AS 
	(
		SELECT	app.application_id,
				COALESCE(SUM(l.count), 0) AS login_count,
				COALESCE(SUM(CASE WHEN l.period = 1 THEN l.count ELSE 0 END), 0) AS login_count_1,
				COALESCE(SUM(CASE WHEN l.period = 2 THEN l.count ELSE 0 END), 0) AS login_count_2
		FROM Applications AS app
			INNER JOIN Logs AS l
			ON l.application_id = app.application_id AND l.action = N'Login'
		GROUP BY app.application_id
	),
	AggregatedSearch
 AS 
	(
		SELECT	app.application_id,
				COALESCE(SUM(l.count), 0) AS search_count,
				COALESCE(SUM(CASE WHEN l.period = 1 THEN l.count ELSE 0 END), 0) AS search_count_1,
				COALESCE(SUM(CASE WHEN l.period = 2 THEN l.count ELSE 0 END), 0) AS search_count_2
		FROM Applications AS app
			INNER JOIN Logs AS l
			ON l.application_id = app.application_id AND l.action = N'Search'
		GROUP BY app.application_id
	),
	AggregatedFiles
 AS 
	(
		SELECT	app.application_id,
				COALESCE(COUNT(f.file_id), 0) AS attachments,
				COALESCE(COUNT(CASE WHEN f.period = 1 THEN f.file_id ELSE NULL END), 0) AS attachments_1,
				COALESCE(COUNT(CASE WHEN f.period = 2 THEN f.file_id ELSE NULL END), 0) AS attachments_2,
				ROUND(CAST(SUM(COALESCE(f.size, 0)) AS float) / 1024 / 1024, 2) AS attachment_size_m_b,
				ROUND(CAST(SUM(COALESCE(CASE WHEN f.period = 1 THEN f.size ELSE 0 END, 0)) AS float) / 1024 / 1024, 2) AS attachment_size_m_b_1,
				ROUND(CAST(SUM(COALESCE(CASE WHEN f.period = 2 THEN f.size ELSE 0 END, 0)) AS float) / 1024 / 1024, 2) AS attachment_size_m_b_2
		FROM Applications AS app
			INNER JOIN Files AS f
			ON f.application_id = app.application_id
		GROUP BY app.application_id
	),
	Aggregated
 AS 
	(
		SELECT	app.title,
				app.members_count,
				app.templates_count AS total_templates_count,
				COALESCE(nd.created_nodes_count, 0) AS created_nodes_count,
				COALESCE(nd.created_nodes_count_1, 0) AS created_nodes_count_1,
				COALESCE(nd.created_nodes_count_2, 0) AS created_nodes_count_2,
				COALESCE(nd.used_templates_count, 0) AS used_templates_count,
				COALESCE(nd.used_templates_count_1, 0) AS used_templates_count_1,
				COALESCE(nd.used_templates_count_2, 0) AS used_templates_count_2,
				COALESCE(lg.login_count, 0) AS login_count,
				COALESCE(lg.login_count_1, 0) AS login_count_1,
				COALESCE(lg.login_count_2, 0) AS login_count_2,
				COALESCE(sh.search_count, 0) AS search_count,
				COALESCE(sh.search_count_1, 0) AS search_count_1,
				COALESCE(sh.search_count_2, 0) AS search_count_2,
				COALESCE(f.attachments, 0) AS attachments,
				COALESCE(f.attachments_1, 0) AS attachments_1,
				COALESCE(f.attachments_2, 0) AS attachments_2,
				COALESCE(f.attachment_size_m_b, 0) AS attachment_size_m_b,
				COALESCE(f.attachment_size_m_b_1, 0) AS attachment_size_m_b_1,
				COALESCE(f.attachment_size_m_b_2, 0) AS attachment_size_m_b_2
		FROM Applications AS app
			LEFT JOIN AggregatedNodes AS nd
			ON nd.application_id = app.application_id
			LEFT JOIN AggregatedLogin AS lg
			ON lg.application_id = app.application_id
			LEFT JOIN AggregatedSearch AS sh
			ON sh.application_id = app.application_id
			LEFT JOIN AggregatedFiles AS f
			ON f.application_id = app.application_id
	)
	SELECT	a.title AS team_name,
			a.members_count,
			a.total_t_emplates_count,
			a.created_nodes_count,
			a.created_nodes_count_1,
			a.created_nodes_count_2,
			CAST(ROUND((CASE 
				WHEN a.created_nodes_count_1 = 0 THEN 0 
				ELSE ((CAST(a.created_nodes_count_2 AS float) / CAST(a.created_nodes_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS created_nodes_change,
			a.used_templates_count,
			a.used_templates_count_1,
			a.used_templates_count_2,
			CAST(ROUND((CASE 
				WHEN a.used_templates_count_1 = 0 THEN 0 
				ELSE ((CAST(a.used_templates_count_2 AS float) / CAST(a.used_templates_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS used_templates_change,
			a.login_count,
			a.login_count_1,
			a.login_count_2,
			CAST(ROUND((CASE 
				WHEN a.login_count_1 = 0 THEN 0 
				ELSE ((CAST(a.login_count_2 AS float) / CAST(a.login_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS login_count_change,
			a.search_count,
			a.search_count_1,
			a.search_count_2,
			CAST(ROUND((CASE 
				WHEN a.search_count_1 = 0 THEN 0 
				ELSE ((CAST(a.search_count_2 AS float) / CAST(a.search_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS search_count_change,
			a.attachments,
			a.attachments_1,
			a.attachments_2,
			CAST(ROUND((CASE 
				WHEN a.attachments_1 = 0 THEN 0 
				ELSE ((CAST(a.attachments_2 AS float) / CAST(a.attachments_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS attachments_change,
			a.attachment_size_m_b,
			a.attachment_size_m_b_1,
			a.attachment_size_m_b_2,
			CAST(ROUND((CASE 
				WHEN a.attachment_size_m_b_1 = 0 THEN 0 
				ELSE ((CAST(a.attachment_size_m_b_2 AS float) / CAST(a.attachment_size_m_b_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS attachment_size_m_b_change
	FROM Aggregated AS a
END;

DROP PROCEDURE IF EXISTS fg_forms_list_report;

CREATE PROCEDURE fg_forms_list_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_form_id					UUID,
    vr_lower_creation_date_limit TIMESTAMP,
    vr_upper_creation_date_limit TIMESTAMP,
    vr_form_filtersTemp		FormFilterTableType readonly,
    vr_delimiter				char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_filters FormFilterTableType
	INSERT INTO vr_form_filters SELECT * FROM vr_form_filtersTemp
	
	DECLARE vr_results Table (
		InstanceID_Hide UUID primary key clustered,
		CreationDate TIMESTAMP,
		CreatorUserID_Hide UUID,
		CreatorName VARCHAR(1000),
		CreatorUserName VARCHAR(1000)
	)
	
	INSERT INTO vr_results (
		InstanceID_Hide, 
		CreationDate, 
		CreatorUserID_Hide, 
		CreatorName, 
		CreatorUserName
	)
	SELECT	fi.instance_id, 
			fi.creation_date,
			fi.creator_user_id,
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))),
			un.username
	FROM fg_form_instances AS fi
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = fi.creator_user_id
	WHERE fi.application_id = vr_application_id AND fi.form_id = vr_form_id AND
		(vr_lower_creation_date_limit IS NULL OR fi.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR fi.creation_date <= vr_upper_creation_date_limit) AND
		fi.deleted = FALSE
	
	DECLARE vr_instanceIDs GuidTableType
		
	INSERT INTO vr_instanceIDs
	SELECT ref.instance_id_hide
	FROM vr_results AS ref
	
	IF (SELECT COUNT(ref.element_id) FROM vr_form_filters AS ref) > 0 BEGIN
		DELETE I
		FROM vr_instanceIDs AS i
			LEFT JOIN fg_fn_filter_instances(
				vr_application_id, NULL, vr_instanceIDs, vr_form_filters, vr_delimiter, 1
			) AS ref
			ON ref.instance_id = i.value
		WHERE ref.instance_id IS NULL
	END
	
	SELECT r.*
	FROM vr_instanceIDs AS i
		INNER JOIN vr_results AS r
		ON r.instance_id_hide = i.value
	ORDER BY r.creation_date DESC
	
	SELECT ('{' +
			'"CreatorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'}' +
		   '}') AS actions

	
	-- Second Part: Describes the Third Part
	SELECT CAST(efe.element_id AS varchar(50)) AS column_name, efe.title AS translation,
		CASE
			WHEN efe.type = N'Binary' THEN N'bool'
			WHEN efe.type = N'Number' THEN N'double'
			WHEN efe.type = N'Date' THEN N'datetime'
			WHEN efe.type = N'User' THEN N'user'
			WHEN efe.type = N'Node' THEN N'node'
			ELSE N'string'
		END AS type
	FROM fg_extended_form_elements AS efe
	WHERE efe.application_id = vr_application_id AND 
		efe.form_id = vr_form_id AND efe.deleted = FALSE
	ORDER BY efe.sequence_number ASC
	
	SELECT ('{"IsDescription": "true"}') AS info
	-- end of Second Part
	
	-- Third Part: The Form Info
	DECLARE vr_element_ids GuidTableType
	DECLARE vr_fake_owner_ids GuidTableType, vr_fake_filters FormFilterTableType
	
	EXEC fg_p_get_form_records vr_application_id, vr_form_id, vr_element_ids, 
		vr_instanceIDs, vr_fake_owner_ids, vr_fake_filters, NULL, 1000000, NULL, NULL
	
	SELECT ('{' +
		'"ColumnsMap": "InstanceID_Hide:InstanceID",' +
		'"ColumnsToTransfer": "' + STUFF((
			SELECT ',' + CAST(efe.element_id AS varchar(50))
			FROM fg_extended_form_elements AS efe
			WHERE efe.application_id = vr_application_id AND 
				efe.form_id = vr_form_id AND efe.deleted = FALSE
			ORDER BY efe.sequence_number ASC
			FOR xml path('a'), type
		).value('.','nvarchar(max)'), 1, 1, '') + '"' +
	   '}') AS info
	-- End of Third Part
END;


DROP PROCEDURE IF EXISTS fg_poll_detail_report;

CREATE PROCEDURE fg_poll_detail_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_poll_id			UUID,
    vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	a.title, 
			a.user_id AS user_id_hide,
			LTRIM(RTRIM(COALESCE(a.first_name, N'') + N' ' + COALESCE(a.last_name, N''))) AS full_name, 
			a.username, 
			a.membership_node_id AS node_id_hide,
			nd.name AS node_name,
			a.value,
			a.number_value
	FROM (
			SELECT	MAX(x.seq) AS seq,
					x.user_id,
					MAX(un.first_name) AS first_name, 
					MAX(un.last_name) AS last_name, 
					MAX(un.username) AS username,
					MAX(x.title) AS title,
					MAX(x.value) AS value,
					MAX(x.float_value) AS number_value,
					CAST(MAX(CAST(nm.node_id AS varchar(50))) AS uuid) AS membership_node_id
			FROM (
					SELECT	i.creator_user_id AS user_id, 
							fe.element_id AS element_id,
							fe.title,
							fe.sequence_number AS seq,
							fg_fn_to_string(vr_application_id, e.element_id, e.type, 
								e.text_value, e.float_value, e.bit_value, e.date_value) AS value,
							e.float_value
					FROM fg_form_instances AS i
						INNER JOIN fg_instance_elements AS e
						ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.deleted = FALSE
						INNER JOIN fg_extended_form_elements AS fe
						ON fe.application_id = vr_application_id AND fe.element_id = e.ref_element_id AND fe.deleted = FALSE
					WHERE i.application_id = vr_application_id AND i.owner_id = vr_poll_id AND i.deleted = FALSE
				) AS x
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = x.user_id
				LEFT JOIN cn_view_node_members AS nm
				ON vr_nodeTypeID IS NOT NULL AND nm.application_id = vr_application_id AND
					nm.node_type_id = vr_nodeTypeID AND nm.user_id = un.user_id AND nm.is_pending = FALSE
			WHERE COALESCE(x.value, N'') <> N''
			GROUP BY x.element_id, x.user_id
		) AS a
		LEFT JOIN cn_nodes AS nd
		ON vr_nodeTypeID IS NOT NULL AND nd.application_id = vr_application_id AND nd.node_id = a.membership_node_id
	ORDER BY a.first_name ASC, a.last_name ASC, a.seq ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;

DROP PROCEDURE IF EXISTS cn_nodes_list_report;

CREATE PROCEDURE cn_nodes_list_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_nodeTypeID				UUID,
    vr_searchText			 VARCHAR(1000),
    vr_status					varchar(100),
    vr_min_contributors_count INTEGER,
    vr_lower_creation_date_limit TIMESTAMP,
    vr_upper_creation_date_limit TIMESTAMP,
    vr_form_filtersTemp		FormFilterTableType readonly,
    vr_delimiter				char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_filters FormFilterTableType
	INSERT INTO vr_form_filters SELECT * FROM vr_form_filtersTemp
	
	SET vr_searchText = gfn_get_search_text(vr_searchText)
	
	DECLARE vr_results Table (
		NodeID_Hide UUID primary key clustered,
		Name VARCHAR(1000),
		AdditionalID varchar(1000),
		NodeType VARCHAR(1000),
		Classification VARCHAR(250),
		Description_HTML VARCHAR(max),
		CreationDate TIMESTAMP,
		PublicationDate TIMESTAMP,
		CreatorUserID_Hide UUID,
		CreatorName VARCHAR(1000),
		CreatorUserName VARCHAR(1000),
		OwnerID_Hide UUID,
		OwnerName VARCHAR(1000),
		OwnerType VARCHAR(1000),
		Score float,
		Status_Dic VARCHAR(100),
		WFState VARCHAR(1000),
		UsersCount INTEGER,
		Collaboration float,
		MaxCollaboration float,
		UploadSize float
	)
	
	IF vr_searchText IS NULL BEGIN
		INSERT INTO vr_results
		SELECT	nd.node_id AS node_id_hide,
				nd.node_name AS name,
				nd.node_additional_id AS additional_id,
				nd.type_name AS node_type,
				conf.level AS classification,
				nd.description AS description_h_t_m_l,
				nd.creation_date,
				nd.publication_date,
				nd.creator_user_id AS creator_user_id_hide,
				(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')) AS creator_name,
				un.username AS creator_username,
				nd.owner_id AS owner_id_hide,
				ow.node_name AS owner_name,
				ow.type_name AS owner_type,
				nd.score,
				nd.status,
				nd.wf_state,
				ref.users_count,
				ref.collaboration,
				ref.max_collaboration,
				ref.upload_size
		FROM (
				SELECT	nd.node_id, 
						COALESCE(COUNT(nc.user_id), 0) AS users_count, 
						CASE
							WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
							ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
						END AS collaboration,
						COALESCE(MAX(nc.collaboration_share), 0) AS max_collaboration,
						SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0) AS upload_size
				FROM cn_nodes AS nd
					LEFT JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND 
						nc.node_id = nd.node_id AND nc.deleted = FALSE
					LEFT JOIN dct_files AS f
					ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
						(f.owner_type = N'Node') AND f.deleted = FALSE
				WHERE nd.application_id = vr_application_id AND 
					(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
					(vr_status IS NULL OR nd.status = vr_status) AND nd.deleted = FALSE AND
					(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
					(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
				GROUP BY nd.node_id
			) AS ref
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
			LEFT JOIN cn_view_nodes_normal AS ow
			ON ow.application_id = vr_application_id AND ow.node_id = nd.owner_id
			LEFT JOIN prvc_view_confidentialities AS conf
			ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
		WHERE (vr_min_contributors_count IS NULL OR ref.users_count >= vr_min_contributors_count)
	END
	ELSE BEGIN
		INSERT INTO vr_results
		SELECT	nd.node_id AS node_id_hide,
				nd.node_name AS name,
				nd.node_additional_id AS additional_id,
				nd.type_name AS node_type,
				conf.level AS classification,
				nd.description AS description_h_t_m_l,
				nd.creation_date,
				nd.publication_date,
				nd.creator_user_id AS creator_user_id_hide,
				(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')) AS creator_name,
				un.username AS creator_username,
				nd.owner_id AS owner_id_hide,
				ow.node_name AS owner_name,
				ow.type_name AS owner_type,
				nd.score,
				nd.status,
				nd.wf_state,
				ref.users_count,
				ref.collaboration,
				ref.max_collaboration,
				ref.upload_size
		FROM (
				SELECT	nd.node_id, 
						COALESCE(COUNT(nc.user_id), 0) AS users_count, 
						CASE
							WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
							ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
						END AS collaboration,
						COALESCE(MAX(nc.collaboration_share), 0) AS max_collaboration,
						SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0) AS upload_size
				FROM CONTAINSTABLE(cn_nodes, (name), vr_searchText) AS srch
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = srch.key
					LEFT JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND 
						nc.node_id = nd.node_id AND nc.deleted = FALSE
					LEFT JOIN dct_files AS f
					ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
						(f.owner_type = N'Node') AND f.deleted = FALSE
				WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
					(vr_status IS NULL OR nd.status = vr_status) AND nd.deleted = FALSE AND
					(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
					(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
				GROUP BY nd.node_id
			) AS ref
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
			LEFT JOIN cn_view_nodes_normal AS ow
			ON ow.application_id = vr_application_id AND ow.node_id = nd.owner_id
			LEFT JOIN prvc_view_confidentialities AS conf
			ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
		WHERE (vr_min_contributors_count IS NULL OR ref.users_count >= vr_min_contributors_count)
	END
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids
	SELECT ref.node_id_hide
	FROM vr_results AS ref
	
	DECLARE vr_instanceIDs GuidTableType
	
	DECLARE vr_form_id UUID = NULL
	
	IF vr_nodeTypeID IS NOT NULL BEGIN
		SET vr_form_id = (
			SELECT TOP(1) FormID
			FROM fg_form_owners
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_nodeTypeID AND deleted = FALSE
		)
	END
	
	IF vr_form_id IS NOT NULL AND (SELECT COUNT(ref.element_id) FROM vr_form_filters AS ref) > 0 BEGIN
		DECLARE vr_form_instance_owners Table (InstanceID UUID, OwnerID UUID)
	
		INSERT INTO vr_form_instance_owners (InstanceID, OwnerID)
		SELECT fi.instance_id, fi.owner_id
		FROM vr_node_ids AS ref 
			INNER JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.owner_id = ref.value AND fi.deleted = FALSE
		
		INSERT INTO vr_instanceIDs (Value)
		SELECT DISTINCT ref.instance_id
		FROM vr_form_instance_owners AS ref
		
		DELETE N
		FROM vr_node_ids AS n
			LEFT JOIN vr_form_instance_owners AS o
			ON o.owner_id = n.value
			LEFT JOIN fg_fn_filter_instances(
				vr_application_id, NULL, vr_instanceIDs, vr_form_filters, vr_delimiter, 1
			) AS ref
			ON ref.instance_id = o.instance_id
		WHERE ref.instance_id IS NULL
		
		DELETE I
		FROM vr_instanceIDs AS i
			LEFT JOIN vr_form_instance_owners AS o
			LEFT JOIN vr_node_ids AS n
			ON n.value = o.owner_id
			ON o.instance_id = i.value
		WHERE o.instance_id IS NULL OR n.value IS NULL
	END
	
	SELECT r.*
	FROM vr_node_ids AS n
		INNER JOIN vr_results AS r
		ON r.node_id_hide = n.value
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"CreatorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'},' +
			'"OwnerName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "OwnerID_Hide"}' +
			'},' +
			'"Contributor": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "ContributorID_Hide"}' +
			'},' +
			'"UsersCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "CreatorUsersReport",' +
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Name"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions

	IF vr_form_id IS NOT NULL AND EXISTS(
		SELECT TOP(1) *
		FROM cn_extensions AS ex
		WHERE ex.application_id = vr_application_id AND 
			ex.owner_id = vr_nodeTypeID AND ex.extension = N'Form' AND ex.deleted = FALSE
	) BEGIN
		-- Second Part: Describes the Third Part
		SELECT CAST(efe.element_id AS varchar(50)) AS column_name, efe.title AS translation,
			CASE
				WHEN efe.type = N'Binary' THEN N'bool'
				WHEN efe.type = N'Number' THEN N'double'
				WHEN efe.type = N'Date' THEN N'datetime'
				WHEN efe.type = N'User' THEN N'user'
				WHEN efe.type = N'Node' THEN N'node'
				ELSE N'string'
			END AS type
		FROM fg_extended_form_elements AS efe
		WHERE efe.application_id = vr_application_id AND 
			efe.form_id = vr_form_id AND efe.deleted = FALSE
		ORDER BY efe.sequence_number ASC
		
		SELECT ('{"IsDescription": "true"}') AS info
		-- end of Second Part
		
		-- Third Part: The Form Info
		DECLARE vr_element_ids GuidTableType
		DECLARE vr_fake_owner_ids GuidTableType, vr_fake_filters FormFilterTableType
		
		EXEC fg_p_get_form_records vr_application_id, vr_form_id, vr_element_ids, 
			vr_instanceIDs, vr_fake_owner_ids, vr_fake_filters, NULL, 1000000, NULL, NULL
		
		SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:OwnerID",' +
			'"ColumnsToTransfer": "' + STUFF((
				SELECT ',' + CAST(efe.element_id AS varchar(50))
				FROM fg_extended_form_elements AS efe
				WHERE efe.application_id = vr_application_id AND 
					efe.form_id = vr_form_id AND efe.deleted = FALSE
				ORDER BY efe.sequence_number ASC
				FOR xml path('a'), type
			).value('.','nvarchar(max)'), 1, 1, '') + '"' +
		   '}') AS info
		-- End of Third Part
	END
	
	
	-- Add Contributor Columns
	
	DECLARE vr_proc VARCHAR(max) = N''
	
	SELECT x.*
	INTO #Result
	FROM (
			SELECT	c.node_id, 
					CAST(c.user_id AS varchar(50)) AS unq,
					c.user_id, 
					c.collaboration_share AS share,
					ROW_NUMBER() OVER (PARTITION BY c.node_id ORDER BY c.collaboration_share DESC, c.user_id DESC) AS row_number
			FROM vr_node_ids AS i_ds
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND c.node_id = i_ds.value AND c.deleted = FALSE
		) AS x
		
	DECLARE vr_count INTEGER = (SELECT MAX(RowNumber) FROM #Result)
	DECLARE vr_itemsList varchar(max) = N'', vr_selectList varchar(max) = N'', vr_cols_to_transfer varchar(max) = N''
	
	SET vr_proc = N''

	DECLARE vr_ind INTEGER = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_tmp varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_selectList = vr_selectList + '[' + vr_tmp + '] AS contributor_id_hide_' + vr_tmp + '], ' + 
			'CAST(NULL AS varchar(500)) AS contributor_' + vr_tmp + '], ' +
			'CAST(NULL AS float) AS contributor_share_' + vr_tmp + ']'
			
		SET vr_itemsList = vr_itemsList + '[' + vr_tmp + ']'
		
		SET vr_proc = vr_proc + 
			'SELECT ''ContributorID_Hide_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''Contributor_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''ContributorShare_' + vr_tmp + ''' AS column_name, null AS translation, ''double'' AS type '
			
		SET vr_cols_to_transfer = vr_cols_to_transfer + 
			'ContributorID_Hide_' + vr_tmp + ',Contributor_' + vr_tmp + ',ContributorShare_' + vr_tmp
		
		IF vr_ind > 0 BEGIN 
			SET vr_selectList = vr_selectList + ', '
			SET vr_itemsList = vr_itemsList + ', '
			SET vr_proc = vr_proc + N'UNION ALL '
			SET vr_cols_to_transfer = vr_cols_to_transfer + ','
		END
		
		SET vr_ind = vr_ind - 1
	END
	
	-- Second Part: Describes the Third Part
	EXEC (vr_proc)
	
	SELECT ('{"IsDescription": "true"}') AS info
	-- end of Second Part

	-- Third Part: The Data
	SET vr_proc = 
		'SELECT NodeID AS node_id_hide, ' + vr_selectList + 
		'INTO #Final ' +
		'FROM ( ' +
				'SELECT NodeID, unq, RowNumber ' +
				'FROM #Result ' +
			') AS p ' +
			'PIVOT (MAX(unq) FOR RowNumber IN (' + vr_itemsList + ')) AS pvt '

	SET vr_ind = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_no varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET Contributor_' + vr_no + ' = LTRIM(RTRIM(COALESCE(un.first_name, N'''') + N'' '' + COALESCE(un.last_name, N''''))) ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN users_normal AS un ' + 
				'ON un.application_id = ''' + CAST(vr_application_id AS varchar(50)) + ''' AND un.user_id = f.contributor_id_hide_' + vr_no + ' '
				
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET ContributorShare_' + vr_no + ' = r.share ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN #Result AS r ' + 
				'ON r.node_id = f.node_id_hide AND r.user_id = f.contributor_id_hide_' + vr_no + ' '
		
		SET vr_ind = vr_ind - 1
	END

	SET vr_proc = vr_proc + 'SELECT * FROM #Final'

	EXEC (vr_proc)
	
	SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:NodeID_Hide",' +
			'"ColumnsToTransfer": "' + vr_cols_to_transfer + '"' +
		   '}') AS info
	-- end of Third Part
	
	-- end of Add Contributor Columns
END;


DROP PROCEDURE IF EXISTS cn_most_favorite_nodes_report;

CREATE PROCEDURE cn_most_favorite_nodes_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_count		 INTEGER,
	vr_nodeTypeID		UUID,
	vr_beginDate	 TIMESTAMP,
	vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_count IS NULL SET vr_count = 20
	
	SELECT TOP(vr_count) 
		nd.node_id AS node_id_hide, 
		nd.node_name, 
		nd.type_name, 
		conf.level AS classification,
		ref.cnt AS count
	FROM (
			SELECT nl.node_id, COUNT(nl.user_id) AS cnt
			FROM cn_node_likes AS nl
			WHERE nl.application_id = vr_application_id AND 
				(vr_beginDate IS NULL OR nl.like_date >= vr_beginDate) AND
				(vr_finish_date IS NULL OR nl.like_date <= vr_finish_date) AND
				nl.deleted = FALSE
			GROUP BY nl.node_id
		) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND nd.deleted = FALSE
	ORDER BY ref.cnt DESC
	
	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_creator_users_report;

CREATE PROCEDURE cn_creator_users_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_node_id					UUID,
	vr_membershipNodeTypeID	UUID,
	vr_membershipNodeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT nc.user_id AS user_id_hide,
		(un.first_name + N' ' + un.last_name) AS name, un.username AS username,
		nc.collaboration_share AS collaboration
	FROM cn_node_creators AS nc
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nc.user_id
	WHERE nc.application_id = vr_application_id AND nc.node_id = vr_node_id AND nc.deleted = FALSE AND
		((vr_membershipNodeID IS NULL AND vr_membershipNodeTypeID IS NULL) OR EXISTS(
			SELECT TOP(1) *
			FROM cn_view_node_members AS nm
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nm.node_id
			WHERE nm.application_id = vr_application_id AND 
				(
					(vr_membershipNodeID IS NULL AND nd.node_type_id = vr_membershipNodeTypeID) OR
					(vr_membershipNodeID IS NOT NULL AND nd.node_id = vr_membershipNodeID)
				) AND nm.user_id = un.user_id AND nm.is_pending = FALSE AND nd.deleted = FALSE
		))

	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_node_creators_report;

CREATE PROCEDURE cn_node_creators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_strUserIDs				varchar(max),
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_showPersonalItems	 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_node_ids GuidTableType, vr_nodeUserIDs GuidTableType
	
	INSERT INTO vr_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_nodeUserIDs
	EXEC cn_p_get_member_user_ids vr_application_id, vr_node_ids, N'Accepted', NULL
	
	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM vr_nodeUserIDs AS ref
	WHERE ref.value NOT IN (SELECT u.value FROM vr_user_ids AS u)
	
	IF((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		INSERT INTO vr_user_ids
		SELECT UserID
		FROM users_normal
		WHERE ApplicationID = vr_application_id AND is_approved = TRUE
	END

	DECLARE vr_dep_type_ids GuidTableType
	INSERT INTO vr_dep_type_ids (Value)
	SELECT ref.node_type_id
	FROM cn_fn_get_department_node_type_ids(vr_application_id) AS ref

	SELECT un.user_id AS user_id_hide, 
		CAST(MAX(CAST(nd.node_id AS varchar(36))) AS uuid) AS department_id_hide,
		(MAX(un.first_name) + N' ' + MAX(un.last_name)) AS name, 
		MAX(un.username) AS username,  
		MAX(nd.name) AS department, 
		MAX(ref.count) AS count, 
		MAX(ref.personal) AS personal_count, 
		MAX(ref.group) AS group_count, 
		MAX(ref.collaboration) AS collaboration,
		MAX(ref.upload_size) AS upload_size
	FROM
		(
			SELECT nc.user_id, 
				COUNT(nc.node_id) AS count,
				SUM(
					CASE
						WHEN nc.collaboration_share = 100 THEN 1
						ELSE 0
					END
				) AS personal,
				SUM(
					CASE
						WHEN nc.collaboration_share = 100 THEN 0
						ELSE 1
					END
				) AS group,
				CASE
					WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
					ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
				END AS collaboration,
				SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0) AS upload_size
			FROM vr_user_ids AS uds
				INNER JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.user_id = uds.value
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
				LEFT JOIN dct_files AS f
				ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
					(f.owner_type = N'Node') AND f.deleted = FALSE
			WHERE nc.deleted = FALSE AND nd.deleted = FALSE AND
				(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
				(vr_showPersonalItems IS NULL OR
					(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
					(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
				) AND
				(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nc.user_id
		) AS ref
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND ref.user_id = un.user_id
		LEFT JOIN cn_node_members AS nm
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_type_id IN (SELECT Value FROM vr_dep_type_ids) AND nd.deleted = FALSE
		ON nm.application_id = vr_application_id AND 
			nm.node_id = nd.node_id AND  nm.user_id = un.user_id AND nm.deleted = FALSE
	GROUP BY un.user_id
	ORDER BY MAX(ref.count) DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Department": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DepartmentID_Hide"}' +
			'},' +
		    '"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[name] (~[username])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": null}' + 
		   	'},' +
		    '"PersonalCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[name] (~[username])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": true}' + 
		   	'},' +
		   	'"GroupCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[name] (~[username])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": false}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_user_created_nodes_report;

CREATE PROCEDURE cn_user_created_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_user_id					UUID,
	vr_showPersonalItems	 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	SELECT	nc.node_id AS node_id_hide, 
			nd.name AS node_name, 
			nd.additional_id AS additional_id,
			conf.level AS classification,
			nc.collaboration_share, nd.creation_date AS creation_date,
			COALESCE((
				SELECT SUM(COALESCE(f.size, 0))
				FROM dct_files AS f
				WHERE f.application_id = vr_application_id AND f.owner_id = nc.node_id AND 
					(f.owner_type = N'Node') AND f.deleted = FALSE
			), 0) / (1024.0 * 1024.0) AS upload_size
	FROM cn_node_creators AS nc
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE nc.application_id = vr_application_id AND 
		nc.user_id = vr_user_id AND nc.deleted = FALSE AND 
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
		nd.deleted = FALSE AND
		(vr_showPersonalItems IS NULL OR
			(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
			(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
		) AND
		(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
	
	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_nodes_created_nodes_report;

CREATE PROCEDURE cn_nodes_created_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_showPersonalItems	 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	IF vr_creatorNodeTypeID IS NOT NULL AND (SELECT COUNT(*) FROM vr_node_ids) = 0 BEGIN
		INSERT INTO vr_node_ids
		SELECT NodeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_creatorNodeTypeID AND deleted = FALSE
	END
	

	SELECT	nd.node_id AS node_id_hide, 
			MAX(nd.node_name) AS node, 
			MAX(nd.type_name) AS node_type, 
			COUNT(ref.created_node_id) AS count, 
			SUM(ref.personal) AS personal_count, 
			(COUNT(ref.created_node_id) - SUM(ref.personal)) AS group_count, 
			AVG(ref.collaboration) AS collaboration,
			SUM(ref.published) AS published,
			SUM(ref.sent_to_admin) AS sent_to_admin,
			SUM(ref.sent_to_evaluators) AS sent_to_evaluators,
			SUM(ref.accepted) AS accepted,
			SUM(ref.rejected) AS rejected,
			SUM(ref.upload_size) AS upload_size
	FROM
		(
			SELECT nm.node_id, nc.node_id AS created_node_id, 
				CAST(MAX(CASE WHEN nc.collaboration_share = 100 THEN 1 ELSE 0 END) AS integer) AS personal,
				CASE
					WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
					ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
				END AS collaboration,
				CASE WHEN MAX(CAST(nd.searchable AS integer)) = 1 THEN 1 ELSE 0 END AS published,
				CASE WHEN MAX(nd.status) = N'SentToAdmin' THEN 1 ELSE 0 END AS sent_to_admin,
				CASE WHEN MAX(nd.status) = N'SentToEvaluators' THEN 1 ELSE 0 END AS sent_to_evaluators,
				CASE WHEN MAX(nd.status) = N'Accepted' THEN 1 ELSE 0 END AS accepted,
				CASE WHEN MAX(nd.status) = N'Rejected' THEN 1 ELSE 0 END AS rejected,
				((SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0)) / COUNT(DISTINCT nc.user_id)) AS upload_size
			FROM vr_node_ids AS nds
				INNER JOIN cn_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = nds.value AND nm.deleted = FALSE
				INNER JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.user_id = nm.user_id AND nc.deleted = FALSE
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id AND nd.deleted = FALSE
				LEFT JOIN dct_files AS f
				ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
					(f.owner_type = N'Node') AND f.deleted = FALSE
			WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
				(vr_showPersonalItems IS NULL OR
					(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
					(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
				) AND
				(vr_lower_creation_date_limit IS NULL OR 
					nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR 
					nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nm.node_id, nc.node_id
		) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
	GROUP BY nd.node_id
	ORDER BY COUNT(ref.created_node_id) DESC

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
		   	'"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": null}' + 
		   	'},' +
		   	'"PersonalCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": true}' + 
		   	'},' +
		   	'"GroupCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": false}' + 
		   	'},' +
		   	'"Published": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Published": true}' + 
		   	'},' +
		   	'"SentToAdmin": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "SentToAdmin"}' + 
		   	'},' +
		   	'"SentToEvaluators": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "SentToEvaluators"}' + 
		   	'},' +
		   	'"Accepted": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "Accepted"}' + 
		   	'},' +
		   	'"Rejected": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "Rejected"}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_node_created_nodes_report;

CREATE PROCEDURE cn_node_created_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeID			UUID,
	vr_status					varchar(50),
	vr_showPersonalItems	 BOOLEAN,
	vr_published			 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	nc.node_id AS node_id_hide, 
			MAX(nd.node_name) AS node,
			MAX(nd.node_additional_id) AS additional_id,
			MAX(nd.type_name) AS node_type,
			MAX(conf.level) AS classification,
			CAST(MAX(CAST(nd.creator_user_id AS varchar(40))) AS uuid) AS creator_user_id_hide,
			MAX(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')) AS creator_name,
			MAX(un.username) AS creator_username,
			MAX(nd.creation_date) AS creation_date,
			COALESCE(COUNT(DISTINCT nc.user_id), 0) AS users_count, 
			CASE
				WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
				ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
			END AS collaboration,
			CAST(MAX(CAST(nd.searchable AS integer)) AS boolean) AS published_dic,
			MAX(nd.status) AS status_dic,
			MAX(nd.wf_state) AS workflow_state,
			((SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0)) / COALESCE(COUNT(DISTINCT nc.user_id), 0)) AS upload_size
	FROM cn_node_members AS nm
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.user_id = nm.user_id
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
		LEFT JOIN dct_files AS f
		ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
			(f.owner_type = N'Node') AND f.deleted = FALSE
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE nm.application_id = vr_application_id AND nm.node_id = vr_creatorNodeID AND 
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
		nc.deleted = FALSE AND nd.deleted = FALSE AND nm.deleted = FALSE AND
		(COALESCE(vr_status, N'') = N'' OR nd.status = vr_status) AND
		(vr_showPersonalItems IS NULL OR
			(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
			(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
		) AND
		(vr_published IS NULL OR COALESCE(nd.searchable, TRUE) = vr_published) AND
		(vr_lower_creation_date_limit IS NULL OR 
			nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR 
			nd.creation_date <= vr_upper_creation_date_limit)
	GROUP BY nc.node_id

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"CreatorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'},' +
			'"UsersCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "CreatorUsersReport",' +
		   		'"Rename": {"CreatorNodeID": "MembershipNodeID"}, ' + 
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Node"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_nodes_own_nodes_report;

CREATE PROCEDURE cn_nodes_own_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	IF vr_creatorNodeTypeID IS NOT NULL AND (SELECT COUNT(*) FROM vr_node_ids) = 0 BEGIN
		INSERT INTO vr_node_ids
		SELECT NodeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_creatorNodeTypeID AND deleted = FALSE
	END
	

	SELECT nd.node_id AS node_id_hide, MAX(nd.node_name) AS node, 
		MAX(nd.type_name) AS node_type, MAX(ref.count) AS count
	FROM
		(
			SELECT nd.owner_id, COUNT(DISTINCT nd.node_id) AS count
			FROM vr_node_ids AS nds
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.owner_id = nds.value
			WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
				nd.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR 
					nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR 
					nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nd.owner_id
		) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.owner_id
	GROUP BY nd.node_id
	ORDER BY MAX(ref.count) DESC

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
		   	'"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeOwnNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}} ' +
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_node_own_nodes_report;

CREATE PROCEDURE cn_node_own_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeID			UUID,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	nc.node_id AS node_id_hide, 
			MAX(nd.name) AS node,
			MAX(nd.additional_id) AS additional_id,
			MAX(conf.level) AS classification,
			MAX(nd.creation_date) AS creation_date,
			COUNT(nc.user_id) AS users_count, 
			CASE
				WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
				ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
			END AS collaboration,
			MAX(nd.wf_state) AS workflow_state
	FROM cn_nodes AS nd
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE nd.application_id = vr_application_id AND nd.owner_id = vr_creatorNodeID AND 
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
		nc.deleted = FALSE AND nd.deleted = FALSE AND
		(vr_lower_creation_date_limit IS NULL OR 
			nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR 
			nd.creation_date <= vr_upper_creation_date_limit)
	GROUP BY nc.node_id

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"UsersCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "CreatorUsersReport",' +
		   		'"Rename": {"CreatorNodeID": "MembershipNodeID"}, ' + 
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Node"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_related_nodes_count_report;

CREATE PROCEDURE cn_related_nodes_count_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_nodeTypeID			UUID,
	vr_related_node_type_id	UUID,
	vr_creation_dateFrom TIMESTAMP,
	vr_creation_dateTo	 TIMESTAMP,
	vr_in				 BOOLEAN,
	vr_out			 BOOLEAN,
	vr_inTags			 BOOLEAN,
	vr_outTags		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_ids GuidTableType
	DECLARE vr_node_type_ids GuidTableType
	DECLARE vr_related_node_type_ids GuidTableType

	IF vr_nodeTypeID IS NULL RETURN

	INSERT INTO vr_node_type_ids (Value)
	VALUES (vr_nodeTypeID)

	IF vr_related_node_type_id IS NOT NULL BEGIN
		INSERT INTO vr_related_node_type_ids (Value)
		VALUES (vr_related_node_type_id)
	END

	SELECT	nd.node_id AS node_id_hide,
			nd.node_name AS name,
			nd.node_additional_id AS additional_id,
			x.cnt AS count
	FROM (
			SELECT ref.node_id, COUNT(ref.related_node_id) AS cnt
			FROM cn_fn_get_related_node_ids(vr_application_id, 
					vr_node_ids, vr_node_type_ids, vr_related_node_type_ids, vr_in, vr_out, vr_inTags, vr_outTags) AS ref
			GROUP BY ref.node_id
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	WHERE (vr_creation_dateFrom IS NULL OR nd.creation_date >= vr_creation_dateFrom) AND
		(vr_creation_dateTo IS NULL OR nd.creation_date < vr_creation_dateTo)
	ORDER BY x.cnt DESC, nd.creation_date DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"Count": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "RelatedNodesReport",' +
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Name"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_related_nodes_report;

CREATE PROCEDURE cn_related_nodes_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_node_id				UUID,
	vr_related_node_type_id	UUID,
	vr_creation_dateFrom TIMESTAMP,
	vr_creation_dateTo	 TIMESTAMP,
	vr_in				 BOOLEAN,
	vr_out			 BOOLEAN,
	vr_inTags			 BOOLEAN,
	vr_outTags		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_ids GuidTableType
	DECLARE vr_node_type_ids GuidTableType
	DECLARE vr_related_node_type_ids GuidTableType

	IF vr_node_id IS NULL RETURN

	INSERT INTO vr_node_ids (Value)
	VALUES (vr_node_id)

	IF vr_related_node_type_id IS NOT NULL BEGIN
		INSERT INTO vr_related_node_type_ids (Value)
		VALUES (vr_related_node_type_id)
	END

	SELECT	r.node_id AS node_id_hide,
			r.node_name AS name,
			r.node_additional_id AS additional_id,
			r.type_name AS node_type
	FROM cn_fn_get_related_node_ids(vr_application_id, 
			vr_node_ids, vr_node_type_ids, vr_related_node_type_ids, vr_in, vr_out, vr_inTags, vr_outTags) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
		INNER JOIN cn_view_nodes_normal AS r
		ON r.application_id = vr_application_id AND r.node_id = ref.related_node_id
	WHERE (vr_creation_dateFrom IS NULL OR nd.creation_date >= vr_creation_dateFrom) AND
		(vr_creation_dateTo IS NULL OR nd.creation_date < vr_creation_dateTo)
	ORDER BY nd.creation_date DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_downloaded_files_report;

CREATE PROCEDURE cn_downloaded_files_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strNodeTypeIDs	varchar(max),
	vr_strUserIDs		varchar(max),
	vr_delimiter		char,
	vr_beginDate	 TIMESTAMP, 
	vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_type_ids GuidTableType
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_node_type_ids (Value)
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_has_user_id BOOLEAN = CAST(COALESCE((SELECT TOP(1) 1 FROM vr_user_ids), 0) AS boolean)
	DECLARE vr_has_node_type_id BOOLEAN = CAST(COALESCE((SELECT TOP(1) 1 FROM vr_node_type_ids), 0) AS boolean)
	
	DECLARE vr_empty UUID = N'00000000-0000-0000-0000-000000000000'
	
	DECLARE vr_logs TABLE (LogID bigint, SubjectID UUID, UserID UUID, date TIMESTAMP)
	
	INSERT INTO vr_logs (LogID, SubjectID, UserID, date)
	SELECT lg.log_id, lg.subject_id, lg.user_id, lg.date
	FROM lg_logs AS lg
	WHERE lg.application_id = vr_application_id AND lg.action = N'Download' AND
		lg.subject_id IS NOT NULL AND lg.subject_id <> vr_empty AND
		(vr_has_user_id = 0 OR lg.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_beginDate IS NULL OR lg.date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR lg.date <= vr_finish_date)
		
	DECLARE vr_file_ids GuidTableType
	
	INSERT INTO vr_file_ids
	SELECT DISTINCT lg.subject_id
	FROM vr_logs AS lg
	WHERE lg.subject_id IS NOT NULL
	
	DECLARE vr_extensions StringTableType
	
	INSERT INTO vr_extensions (Value)
	VALUES (N'jpg'), (N'png'), (N'gif'), (N'jpeg'), (N'bmp')
	
	SELECT TOP(2000)	
			((ROW_NUMBER() OVER (ORDER BY ref.log_id_hide DESC)) +
			(ROW_NUMBER() OVER (ORDER BY ref.log_id_hide ASC)) - 1) AS total_count_hide,
			ref.*
	FROM (
			SELECT	MAX(lg.log_id) AS log_id_hide,
					CAST(MAX(CAST(x.node_id AS varchar(50))) AS uuid) AS node_id_hide,
					CAST(MAX(CAST(un.user_id AS varchar(50))) AS uuid) AS user_id_hide,
					MAX(LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS full_name,
					MAX(un.username) AS username,
					MAX(x.node_name) AS node_name,
					MAX(x.node_type) AS node_type,
					MAX(x.file_name) AS file_name,
					MAX(x.extension) AS extension,
					MAX(lg.date) AS last_download_date,
					COUNT(DISTINCT lg.log_id) AS downloads_count
			FROM vr_logs AS lg
				INNER JOIN dct_fn_get_file_owner_nodes(vr_application_id, vr_file_ids) AS x
				INNER JOIN dct_files AS f
				ON f.application_id = vr_application_id AND f.file_name_guid = x.file_id
				ON f.file_name_guid = lg.subject_id AND
					(vr_has_node_type_id = 0 OR x.node_type_id IN (SELECT a.value FROM vr_node_type_ids AS a))
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = lg.user_id
			WHERE LOWER(COALESCE(x.extension, N'')) NOT IN (SELECT a.value FROM vr_extensions AS a)
			GROUP BY lg.subject_id, lg.user_id
		) AS ref
	ORDER BY ref.log_id_hide DESC

	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;

DROP PROCEDURE IF EXISTS usr_users_list_report;

CREATE PROCEDURE usr_users_list_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_employment_type			varchar(20),
    vr_searchText			 VARCHAR(1000),
    vr_isApproved			 BOOLEAN,
    vr_lowerBirthDateLimit TIMESTAMP,
    vr_upper_birth_date_limit TIMESTAMP,
    vr_lower_creation_date_limit TIMESTAMP,
    vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_get_search_text(vr_searchText)
	
	DECLARE vr_results Table(UserID_Hide UUID primary key clustered,
		Name VARCHAR(1000), UserName VARCHAR(1000), Birthday TIMESTAMP,
		JobTitle VARCHAR(1000), EmploymentType_Dic varchar(50), CreationDate TIMESTAMP,
		DepartmentID_Hide UUID, Department VARCHAR(1000))
	
	IF vr_searchText IS NULL BEGIN
		INSERT INTO vr_results(
			UserID_Hide, Name, UserName, Birthday, JobTitle, EmploymentType_Dic, CreationDate
		)
		SELECT	un.user_id AS user_id_hide,
				LTRIM(RTRIM((COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS name,
				un.username AS username,
				un.birthdate,
				un.job_title,
				un.employment_type,
				un.creation_date
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND
			(vr_employment_type IS NULL OR un.employment_type = vr_employment_type) AND
			(vr_lowerBirthDateLimit IS NULL OR un.birthdate >= vr_lowerBirthDateLimit) AND
			(vr_upper_birth_date_limit IS NULL OR un.birthdate <= vr_upper_birth_date_limit) AND
			(vr_lower_creation_date_limit IS NULL OR un.creation_date >= vr_lower_creation_date_limit) AND
			(vr_upper_creation_date_limit IS NULL OR un.creation_date <= vr_upper_creation_date_limit) AND 
			un.is_approved = COALESCE(vr_isApproved, 1)
	END
	ELSE BEGIN
		INSERT INTO vr_results(
			UserID_Hide, Name, UserName, Birthday, JobTitle, EmploymentType_Dic, CreationDate
		)
		SELECT	un.user_id AS user_id_hide,
				LTRIM(RTRIM((COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS name,
				un.username AS username,
				un.birthdate,
				un.job_title,
				un.employment_type,
				un.creation_date
		FROM CONTAINSTABLE(usr_view_users, 
			(username, first_name, last_name), vr_searchText) AS srch
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = srch.key
		WHERE (vr_employment_type IS NULL OR un.employment_type = vr_employment_type) AND
			(vr_lowerBirthDateLimit IS NULL OR un.birthdate >= vr_lowerBirthDateLimit) AND
			(vr_upper_birth_date_limit IS NULL OR un.birthdate <= vr_upper_birth_date_limit) AND
			(vr_lower_creation_date_limit IS NULL OR un.creation_date >= vr_lower_creation_date_limit) AND
			(vr_upper_creation_date_limit IS NULL OR un.creation_date <= vr_upper_creation_date_limit) AND
			un.is_approved = COALESCE(vr_isApproved, 1)
	END
	
	DECLARE vr_dep_type_ids GuidTableType
	INSERT INTO vr_dep_type_ids (Value)
	SELECT ref.node_type_id
	FROM cn_fn_get_department_node_type_ids(vr_application_id) AS ref
	
	UPDATE R
		SET DepartmentID_Hide = ref.department_id,
			Department = ref.department
	FROM vr_results AS r
		INNER JOIN (
			SELECT t.user_id_hide,
				CAST(MAX(CAST(nd.node_id AS varchar(36))) AS uuid) 
				 AS department_id,
				MAX(nd.name) AS department
			FROM vr_results AS t
				LEFT JOIN cn_node_members AS nm
				LEFT JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND 
					nd.node_type_id IN (SELECT Value FROM vr_dep_type_ids) AND nd.deleted = FALSE
				ON nm.application_id = vr_application_id AND 
					nm.node_id = nd.node_id AND nm.user_id = t.user_id_hide AND nm.deleted = FALSE
			GROUP BY t.user_id_hide
		) AS ref
		ON r.user_id_hide = ref.user_id_hide
		
	
	SELECT * FROM vr_results
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Department": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DepartmentID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_invitations_report;

CREATE PROCEDURE usr_invitations_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_beginDate	 TIMESTAMP,
    vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	WITH X AS(
		SELECT
			i.sender_user_id,
			COUNT(i.id) AS sent_invitations_count,
			COUNT(tu.user_id) AS registered_users_count,
			COUNT(un.user_id) AS activated_users_count
		FROM u_s_r_invitations AS i
			LEFT JOIN u_s_r_temporary_users AS tu
			ON tu.email = i.email
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = tu.user_id
		WHERE i.application_id = vr_application_id AND 
			(vr_beginDate IS NULL OR i.send_date >= vr_beginDate) AND
			(vr_finish_date IS NULL OR i.send_date <= vr_finish_date)
		GROUP BY i.sender_user_id
	)
	SELECT 
		x.sender_user_id AS sender_user_id_hide,
		un.first_name + ' ' + un.last_name AS name,
		x.sent_invitations_count,
		x.registered_users_count,
		x.activated_users_count
	FROM X
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.sender_user_id
	ORDER BY x.sent_invitations_count DESC
	
	SELECT (
		'{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "SenderUserID_Hide"}' +
			'}'+
		'}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_users_membership_flow_report;

CREATE PROCEDURE usr_users_membership_flow_report
	vr_application_id					UUID,
	vr_current_user_id					UUID,
	vr_senderUserID					UUID,
    vr_lowerInvitationSentDateLimit TIMESTAMP,
    vr_upper_invitation_sent_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		un.user_id AS user_id_hide,
		CASE
			WHEN (un.user_id IS NOT NULL) THEN un.first_name + ' ' + un.last_name
			WHEN (tu.user_id IS NOT NULL) THEN tu.first_name + ' ' + tu.last_name 
			ELSE N'بی نام'
		END AS name,
		i.email,
		i.send_date AS received_date,
		tu.creation_date AS registeration_date,
		un.creation_date AS activation_date
	FROM u_s_r_invitations AS i
		LEFT JOIN u_s_r_temporary_users AS tu
		ON tu.email = i.email
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = tu.user_id
	WHERE i.application_id = vr_application_id AND 
		(vr_senderUserID IS NULL OR i.sender_user_id = vr_senderUserID) AND
		(vr_lowerInvitationSentDateLimit IS NULL OR i.send_date >= vr_lowerInvitationSentDateLimit) AND
		(vr_upper_invitation_sent_date_limit IS NULL OR i.send_date <= vr_upper_invitation_sent_date_limit)
	ORDER BY i.send_date DESC
	
	SELECT (
		'{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}'+
		'}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_most_visited_items_report;

CREATE PROCEDURE usr_most_visited_items_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
    vr_itemType			varchar(20),
    vr_nodeTypeID			UUID,
    vr_count			 INTEGER,
    vr_beginDate		 TIMESTAMP,
    vr_finish_date		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_count IS NULL OR vr_count <= 0 SET vr_count = 50
	
	DECLARE vr_results Table (ItemID UUID primary key clustered, 
		VisitsCount INTEGER, LastVisitDate TIMESTAMP)
	
	IF vr_nodeTypeID IS NOT NULL BEGIN
		INSERT INTO vr_results (ItemID, VisitsCount, LastVisitDate)
		SELECT TOP(vr_count) ref.item_id, ref.count, ref.visit_date
		FROM (
				SELECT iv.item_id, COUNT(iv.item_id) AS count, MAX(iv.visit_date) AS visit_date
				FROM usr_item_visits AS iv
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = iv.item_id
				WHERE iv.application_id = vr_application_id AND nd.node_type_id = vr_nodeTypeID AND
					(vr_beginDate IS NULL OR iv.visit_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR iv.visit_date <= vr_finish_date)
				GROUP BY iv.item_id
			) AS ref
		ORDER BY ref.count DESC, ref.visit_date DESC
	END
	ELSE BEGIN
		INSERT INTO vr_results (ItemID, VisitsCount, LastVisitDate)
		SELECT TOP(vr_count) ref.item_id, ref.count, ref.visit_date
		FROM (
				SELECT ItemID, COUNT(ItemID) AS count, MAX(VisitDate) AS visit_date
				FROM usr_item_visits
				WHERE ApplicationID = vr_application_id AND ItemType = vr_itemType AND
					(vr_beginDate IS NULL OR VisitDate >= vr_beginDate) AND
					(vr_finish_date IS NULL OR VisitDate <= vr_finish_date)
				GROUP BY ItemID
			) AS ref
		ORDER BY ref.count DESC, ref.visit_date DESC
	END
	
	IF vr_itemType = N'User' BEGIN
		SELECT r.item_id AS item_id_hide, 
			(un.first_name + N' ' + un.last_name) AS item_name, 
			un.username,
			r.visits_count
		FROM vr_results AS r
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = r.item_id
		ORDER BY r.visits_count DESC, r.last_visit_date DESC
	END
	ELSE BEGIN
		SELECT r.item_id AS item_id_hide, nd.node_name AS item_name, r.visits_count
		FROM vr_results AS r
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = r.item_id
		ORDER BY r.visits_count DESC, r.last_visit_date DESC
	END
END;


DROP PROCEDURE IF EXISTS usr_p_users_performance_report;

CREATE PROCEDURE usr_p_users_performance_report
	vr_application_id			UUID,
    vr_user_group_ids_temp		GuidPairTableType readonly,
    vr_knowledge_type_idsTemp	GuidTableType readonly,
    vr_compensate_per_score	 BOOLEAN,
    vr_compensation_volume		float,
    vr_scoreItemsTemp			FloatStringTableType readonly,
    vr_beginDate			 TIMESTAMP,
    vr_finish_date			 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_users TABLE (UserID UUID primary key clustered, GroupID UUID, GroupName VARCHAR(500)) 
	INSERT INTO vr_users (UserID, GroupID, GroupName)
	SELECT t.first_value, nd.node_id, nd.name
	FROM vr_user_group_ids_temp AS t
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = t.second_value
	
    DECLARE vr_knowledge_type_ids GuidTableType
    INSERT INTO vr_knowledge_type_ids SELECT * FROM vr_knowledge_type_idsTemp
    
    DECLARE vr_scoreItems FloatStringTableType
    INSERT INTO vr_scoreItems SELECT * FROM vr_scoreItemsTemp

	SELECT data.*
	INTO #Results
	FROM (
			-- (1) تعداد به اشتراک گذاری ها روی تخته دانش
			---- ItemName: SharesOnWall ----
			SELECT users.user_id, posts.score, N'AA_SharesOnWall' AS item_name 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT ps.sender_user_id, COALESCE(COUNT(ps.share_id), 0) AS score 
					FROM sh_post_shares AS ps
					WHERE ps.application_id = vr_application_id AND 
						ps.owner_type = N'User' AND ps.deleted = FALSE AND
						(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date)
					GROUP BY ps.sender_user_id
				) AS posts
				ON users.user_id = posts.sender_user_id
			-- end of (1)

			UNION ALL

			-- (8) تعداد نظرات دریافت شده بر روی دانش ها
			---- ItemName: ReceivedSharesOnKnowledges ----
			SELECT usr.user_id, (
				(SELECT COALESCE(COUNT(ps.share_id), 0)
				 FROM sh_post_shares AS ps
					INNER JOIN kw_view_knowledges AS vk
					INNER JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND nc.node_id = vk.knowledge_id
					ON vk.application_id = vr_application_id AND vk.knowledge_id = ps.owner_id
				 WHERE nc.application_id = vr_application_id AND 
					nc.user_id = usr.user_id AND nc.deleted = FALSE AND 
					ps.sender_user_id <> usr.user_id AND ps.owner_type = N'Knowledge' AND
					vk.deleted = FALSE AND ps.deleted = FALSE AND
					(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date))
			), N'AB_ReceivedSharesOnKnowledges'
			FROM vr_users AS usr
			-- end of (8)

			UNION ALL

			-- (9) تعداد نظرهای ارسال کرده بر روی دانش های دیگران
			---- ItemName: SentSharesOnKnowledges ----
			SELECT usr.user_id, (
				SELECT COALESCE(COUNT(ps.share_id), 0)
				FROM sh_post_shares AS ps
					INNER JOIN kw_view_knowledges VK
					ON vk.application_id = vr_application_id AND vk.knowledge_id = ps.owner_id
				WHERE ps.application_id = vr_application_id AND ps.sender_user_id = usr.user_id AND
					ps.owner_type = N'Knowledge' AND ps.deleted = FALSE AND
					(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date) AND
					NOT EXISTS(SELECT TOP(1) * FROM cn_node_creators AS nc
						WHERE nc.node_id = vk.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE)
			), N'AC_SentSharesOnKnowledges'
			FROM vr_users AS usr
			-- end of (9)

			UNION ALL

			-- (10) مجموع صرفه جویی های زمانی دانش های ثبت شده
			---- ItemName: ReceivedTemporalFeedBacks ----
			SELECT usr.user_id, (
				(SELECT COALESCE(SUM(fb.value), 0)
				 FROM kw_feedbacks AS fb
					INNER JOIN kw_view_knowledges AS vk
					INNER JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND nc.node_id = vk.knowledge_id
					ON vk.application_id = vr_application_id AND vk.knowledge_id = fb.knowledge_id
				 WHERE fb.application_id = vr_application_id AND 
					nc.user_id = usr.user_id AND nc.deleted = FALSE AND 
					fb.feedback_type_id = 2 AND fb.user_id <> usr.user_id AND
					vk.deleted = FALSE AND fb.deleted = FALSE AND
					(vr_beginDate IS NULL OR fb.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR fb.send_date <= vr_finish_date))
			), N'AD_ReceivedTemporalFeedBacks'
			FROM vr_users AS usr
			-- end of (10)

			UNION ALL

			-- (11) مجموع صرفه جویی های ریالی دانش های ثبت شده
			---- ItemName: ReceivedFinancialFeedBacks ----
			SELECT usr.user_id, (
				(SELECT COALESCE(SUM(fb.value), 0)
				 FROM kw_feedbacks AS fb
					INNER JOIN kw_view_knowledges AS vk
					INNER JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND nc.node_id = vk.knowledge_id
					ON vk.application_id = vr_application_id AND vk.knowledge_id = fb.knowledge_id
				 WHERE fb.application_id = vr_application_id AND 
					nc.user_id = usr.user_id AND nc.deleted = FALSE AND 
					fb.feedback_type_id = 1 AND fb.user_id <> usr.user_id AND
					vk.deleted = FALSE AND fb.deleted = FALSE AND
					(vr_beginDate IS NULL OR fb.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR fb.send_date <= vr_finish_date))
			), N'AE_ReceivedFinancialFeedBacks'
			FROM vr_users AS usr
			-- end of (11)

			UNION ALL

			-- (12) تعداد صرفه جویی های اعلام کرده بر روی دانش های دیگران
			---- ItemName: SentFeedBacksCount ----
			SELECT usr.user_id, (
				SELECT COUNT(fb.value) 
				FROM kw_feedbacks AS fb
					INNER JOIN kw_view_knowledges AS vk
					ON vk.application_id = vr_application_id AND vk.knowledge_id = fb.knowledge_id
				WHERE fb.application_id = vr_application_id AND 
					fb.user_id = usr.user_id AND fb.deleted = FALSE AND
					(vr_beginDate IS NULL OR fb.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR fb.send_date <= vr_finish_date) AND
					NOT EXISTS(SELECT TOP(1) * FROM cn_node_creators AS nc
						WHERE nc.node_id = vk.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE)
			), N'AF_SentFeedBacksCount'
			FROM vr_users AS usr
			-- end of (12)

			UNION ALL

			-- (13) تعداد سوالات پرسیده شده
			---- ItemName: SentQuestions ----
			SELECT users.user_id, COALESCE(qtn.score, 0), N'AG_SentQuestions' 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT qu.sender_user_id, COUNT(qu.question_id) AS score
					FROM qa_questions AS qu
					WHERE qu.application_id = vr_application_id AND qu.deleted = FALSE AND 
						(vr_beginDate IS NULL OR qu.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR qu.send_date <= vr_finish_date)
					GROUP BY qu.sender_user_id
				) AS qtn
				ON users.user_id = qtn.sender_user_id
			-- end of (13)

			UNION ALL

			-- (14) مجموع امتیاز پاسخ های ارسال شده بر روی سوالات دیگران
			---- ItemName: SentAnswers ----
			SELECT usr.user_id, (
				SELECT COALESCE(COUNT(ans.answer_id), 0)
				FROM qa_answers AS ans
					INNER JOIN qa_questions AS qu
					ON qu.application_id = vr_application_id AND qu.question_id = ans.question_id
				WHERE ans.application_id = vr_application_id AND ans.sender_user_id = usr.user_id AND 
					qu.sender_user_id <> usr.user_id AND ans.deleted = FALSE AND
					(vr_beginDate IS NULL OR ans.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR ans.send_date <= vr_finish_date)
			), N'AH_SentAnswers'
			FROM vr_users AS usr 
			-- end of (14)

			UNION ALL

			-- (15) تعداد ارزیابی اولیه دانش های دیگران
			---- ItemName: KnowledgeOverview ----
			SELECT	usr.user_id,
					SUM(
						CASE 
							WHEN h.knowledge_id IS NOT NULL THEN 1
							ELSE 0
						END
					),
					N'AI_KnowledgeOverview'
			FROM vr_users AS usr
				LEFT JOIN (
					SELECT ROW_NUMBER() OVER (PARTITION BY h.knowledge_id, h.actor_user_id ORDER BY h.id ASC) AS row_number,
						h.knowledge_id,
						h.actor_user_id,
						h.action_date
					FROM kw_history AS h
					WHERE h.application_id = vr_application_id AND h.action IN (
							N'Accept', N'Reject', N'SendBackForRevision', 
							N'SendToEvaluators', N'TerminateEvaluation'
						)
				) AS h
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND 
					nd.node_id = h.knowledge_id AND nd.deleted = FALSE
				ON h.row_number = 1 AND h.actor_user_id = usr.user_id AND
					(vr_beginDate IS NULL OR h.action_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR h.action_date <= vr_finish_date) AND
					NOT EXISTS(
						SELECT TOP(1) * 
						FROM cn_node_creators AS nc
						WHERE nc.application_id = vr_application_id AND 
							nc.node_id = h.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE
					)
			GROUP BY usr.user_id
			-- end of (15)

			UNION ALL

			-- (16) تعداد ارزیابی خبرگی دانش های دیگران
			---- ItemName: KnowledgeEvaluation ----
			SELECT	usr.user_id,
					SUM(
						CASE 
							WHEN h.knowledge_id IS NOT NULL THEN 1
							ELSE 0
						END
					),
					N'AJ_KnowledgeEvaluation'
			FROM vr_users AS usr
				LEFT JOIN (
					SELECT ROW_NUMBER() OVER (PARTITION BY h.knowledge_id, h.actor_user_id ORDER BY h.id ASC) AS row_number,
						h.knowledge_id,
						h.actor_user_id,
						h.action_date
					FROM kw_history AS h
					WHERE h.application_id = vr_application_id AND h.action IN (N'Evaluation')
				) AS h
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND 
					nd.node_id = h.knowledge_id AND nd.deleted = FALSE
				ON h.row_number = 1 AND h.actor_user_id = usr.user_id AND
					(vr_beginDate IS NULL OR h.action_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR h.action_date <= vr_finish_date) AND
					NOT EXISTS(
						SELECT TOP(1) * 
						FROM cn_node_creators AS nc
						WHERE nc.application_id = vr_application_id AND 
							nc.node_id = h.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE
					)
			GROUP BY usr.user_id
			-- end of (16)

			UNION ALL

			-- (17) امتیاز انجمن
			---- ItemName: CommunityScore ----
			SELECT usr.user_id, (
				(
					SELECT COALESCE(COUNT(ans.answer_id), 0)
					FROM qa_answers AS ans
						INNER JOIN qa_questions AS qu
						ON qu.application_id = vr_application_id AND qu.question_id = ans.question_id
					WHERE ans.application_id = vr_application_id AND 
						ans.sender_user_id = usr.user_id AND qu.sender_user_id <> usr.user_id AND 
						ans.deleted = FALSE AND
						(vr_beginDate IS NULL OR ans.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ans.send_date <= vr_finish_date)
				) + (
					SELECT CAST(COALESCE(COUNT(ps.share_id), 0) AS float)
					FROM sh_post_shares AS ps
					WHERE ps.application_id = vr_application_id AND ps.sender_user_id = usr.user_id AND
						ps.owner_type = N'Node' AND ps.deleted = FALSE AND
						(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date)
				)
			), N'AK_CommunityScore'
			FROM vr_users AS usr
			-- end of (17)

			UNION ALL

			-- (18) تعداد تغییرات ویکی تایید شده
			---- ItemName: AcceptedWikiChanges ----
			SELECT users.user_id, COALESCE(cng.score, 0), N'AL_AcceptedWikiChanges' 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT ch.user_id, COUNT(ch.change_id) AS score
					FROM wk_changes AS ch
					WHERE ch.application_id = vr_application_id AND ch.status = N'Accepted' AND
						(vr_beginDate IS NULL OR ch.acception_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ch.acception_date <= vr_finish_date)
					GROUP BY ch.user_id
				) AS cng
				ON users.user_id = cng.user_id
			-- end of (18)

			UNION ALL

			-- (19) تعداد ویکی های داوری کرده به عنوان خبره
			---- ItemName: WikiEvaluation ----
			SELECT users.user_id, COALESCE(cng.score, 0), N'AM_WikiEvaluation' 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT ch.evaluator_user_id, COUNT(ch.change_id) AS score
					FROM wk_changes AS ch
					WHERE ch.application_id = vr_application_id AND 
						(vr_beginDate IS NULL OR ch.evaluation_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ch.evaluation_date <= vr_finish_date)
					GROUP BY ch.evaluator_user_id
				) AS cng
				ON users.user_id = cng.evaluator_user_id
			-- end of (19)

			UNION ALL

			-- (20) تعداد بازدید دیگران از صفحه شخصی
			---- ItemName: PersonalPageVisit ----
			SELECT usr.user_id, 
				(
					SELECT COUNT(iv.user_id) 
					FROM usr_item_visits AS iv
					WHERE iv.application_id = vr_application_id AND iv.item_id = usr.user_id AND
						(vr_beginDate IS NULL OR iv.visit_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR iv.visit_date <= vr_finish_date)
				), N'AN_PersonalPageVisit'
			FROM vr_users AS usr
			-- end of (20)
			
			UNION ALL
			
			-- (N) دانش ها
			SELECT	users.user_id AS user_id, COALESCE(kn.score, 0), kn.registered_type
			FROM vr_users AS users
				LEFT JOIN (
					SELECT	nc.user_id,
							N'AO_Registered_' + REPLACE(CAST(nd.node_type_id AS varchar(100)), '-', '') AS registered_type, 
							SUM(
								CASE
									WHEN (vr_beginDate IS NULL OR nd.creation_date >= vr_beginDate) AND
										(vr_finish_date IS NULL OR nd.creation_date <= vr_finish_date) THEN 1
									ELSE 0
								END * (nc.collaboration_share / 100)
							) AS score
					FROM vr_knowledge_type_ids AS k
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_type_id = k.value
						INNER JOIN cn_node_creators AS nc
						ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
					WHERE nd.deleted = FALSE AND nc.deleted = FALSE
					GROUP BY nc.user_id, nd.node_type_id
				) AS kn
				ON users.user_id = kn.user_id
				
			UNION ALL

			SELECT	users.user_id AS user_id, COALESCE(kn.score, 0), kn.accepted_type_count
			FROM vr_users AS users
				LEFT JOIN (
					SELECT	nc.user_id,
							N'AP_AcceptedCount_' + REPLACE(CAST(nd.node_type_id AS varchar(100)), '-', '') AS accepted_type_count,
							SUM(
								CASE
									WHEN nd.status = N'Accepted' AND 
										(vr_beginDate IS NULL OR COALESCE(nd.publication_date, nd.creation_date) >= vr_beginDate) AND
										(vr_finish_date IS NULL OR COALESCE(nd.publication_date, nd.creation_date) <= vr_finish_date)
										THEN 1
									ELSE 0
								END * (nc.collaboration_share / 100)
							) AS score
					FROM vr_knowledge_type_ids AS k
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_type_id = k.value
						INNER JOIN cn_node_creators AS nc
						ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
					WHERE nd.deleted = FALSE AND nc.deleted = FALSE
					GROUP BY nc.user_id, nd.node_type_id
				) AS kn
				ON users.user_id = kn.user_id
				
			UNION ALL

			SELECT	users.user_id AS user_id, COALESCE(kn.score, 0), kn.accepted_type_score
			FROM vr_users AS users
				LEFT JOIN (
					SELECT	nc.user_id,
							N'AQ_AcceptedScore_' + REPLACE(CAST(nd.node_type_id AS varchar(100)), '-', '') AS accepted_type_score,
							SUM(
								CASE
									WHEN nd.status = N'Accepted' AND 
										(vr_beginDate IS NULL OR COALESCE(nd.publication_date, nd.creation_date) >= vr_beginDate) AND
										(vr_finish_date IS NULL OR COALESCE(nd.publication_date, nd.creation_date) <= vr_finish_date)
										THEN COALESCE(nd.score, 0)
									ELSE 0
								END * (nc.collaboration_share / 100)
							) AS score
					FROM vr_knowledge_type_ids AS k
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_type_id = k.value
						INNER JOIN cn_node_creators AS nc
						ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
					WHERE nd.deleted = FALSE AND nc.deleted = FALSE
					GROUP BY nc.user_id, nd.node_type_id
				) AS kn
				ON users.user_id = kn.user_id
			-- end of (N)
		) AS data
		INNER JOIN vr_scoreItems AS si
		ON si.second_value = data.item_name AND si.first_value > 0
	
	
	DECLARE vr_itemsList VARCHAR(MAX)   

	SELECT vr_itemsList = COALESCE(vr_itemsList + ', ', '') + '[' + ItemName + ']'
	FROM (SELECT DISTINCT ItemName FROM #Results) AS q
	ORDER BY q.item_name
	
	CREATE TABLE #TMPR (UserID_Hide UUID, GroupID_Hide UUID, 
		Name VARCHAR(1000), UserName VARCHAR(256), GroupName VARCHAR(500),
		Score float, Compensation float
	)
	
	INSERT INTO #TMPR (UserID_Hide)
	SELECT DISTINCT UserID
	FROM #Results AS r
	
	-- Compute Users' Scores
	UPDATE T
		SET Score = ref.score
	FROM #TMPR AS t
		INNER JOIN (
			SELECT r.user_id, SUM(COALESCE(s.first_value, 0) * COALESCE(r.score, 0)) AS score
			FROM #Results AS r
				INNER JOIN vr_scoreItems AS s
				ON LOWER(r.item_name) = LOWER(s.second_value)
			GROUP BY r.user_id
		) AS ref
		ON t.user_id_hide = ref.user_id
	-- end of Compute Users' Scores
	
	-- Compute Users' Compensations
	DECLARE vr_scoreReward float = vr_compensation_volume
	
	IF(vr_compensate_per_score IS NULL OR vr_compensate_per_score = 0)
		SET vr_scoreReward = vr_compensation_volume / (SELECT SUM(Score) FROM #TMPR)
	
	UPDATE #TMPR
	SET Compensation = Score * COALESCE(vr_scoreReward, 0)
	-- end of Compute Users' Compensations
	
	-- Determine Full Names & Groups
	UPDATE R
		SET GroupID_Hide = u.group_id,
			Name = LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))),
			UserName = un.username,
			GroupName = u.group_name
	FROM #TMPR AS r
		INNER JOIN vr_users AS u
		ON u.user_id = r.user_id_hide
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = u.user_id
	-- end of Determine Names & Departments
	
	
	EXEC (
		'SELECT ROW_NUMBER() OVER(ORDER BY t.score DESC, t.user_id_hide ASC) AS rank, t.user_id_hide, t.group_id_hide, t.name, t.username, ' +
			't.group_name, t.score, t.compensation, ' + vr_itemsList + ' ' +
		'FROM #TMPR AS t ' +
			'INNER JOIN ( ' +
				'SELECT UserID, ' + vr_itemsList + ' ' +
				'FROM ( ' +
						'SELECT UserID, Score, ItemName ' +
						'FROM #Results ' +
					') AS p ' +
					'PIVOT ' +
					'(SUM(Score) FOR ItemName IN (' + vr_itemsList + ')) AS pvt ' +
			') AS x ' +
			'ON x.user_id = t.user_id_hide ' +
		'ORDER BY t.score DESC, t.user_id_hide ASC'
	)
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"GroupName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "GroupID_Hide"}' +
			'}' +
		   '}') AS actions
	
	SELECT *
	FROM (
		SELECT	'AO_Registered_' + REPLACE(CAST(nt.node_type_id AS varchar(100)), '-', '') AS column_name,
				N'تعداد ''' + nt.name + N''' ثبت شده' AS translation,
				'double' AS type
		FROM vr_knowledge_type_ids AS k
			INNER JOIN cn_node_types AS nt
			ON nt.node_type_id = k.value
			
		UNION ALL
		
		SELECT	'AP_AcceptedCount_' + REPLACE(CAST(nt.node_type_id AS varchar(100)), '-', '') AS column_name,
				N'تعداد ''' + nt.name + N''' تایید شده' AS translation,
				'double' AS type
		FROM vr_knowledge_type_ids AS k
			INNER JOIN cn_node_types AS nt
			ON nt.node_type_id = k.value
		
		UNION ALL
		
		SELECT	'AQ_AcceptedScore_' + REPLACE(CAST(nt.node_type_id AS varchar(100)), '-', '') AS column_name,
				N'جمع امتیازات ''' + nt.name + N''' تایید شده' AS translation,
				'double' AS type
		FROM vr_knowledge_type_ids AS k
			INNER JOIN cn_node_types AS nt
			ON nt.node_type_id = k.value
	) AS x
			
	SELECT ('{"IsDescription": "true", "IsColumnsDictionary": "true"}') AS info
END;


DROP PROCEDURE IF EXISTS usr_users_performance_report;

CREATE PROCEDURE usr_users_performance_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_strUserIDs				varchar(max),
    vr_strNodeIDs				varchar(max),
    vr_strListIDs				varchar(max),
    vr_strKnowledgeTypeIDs	varchar(max),
    vr_delimiter				char,
    vr_beginDate			 TIMESTAMP,
    vr_finish_date			 TIMESTAMP,
    vr_compensate_per_score	 BOOLEAN,
    vr_compensation_volume		float,
    vr_strScoreItems			varchar(max),
    vr_inner_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_list_ids GuidTableType
	
	INSERT INTO vr_list_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strListIDs, vr_delimiter) AS ref
	
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_node_ids) + (SELECT COUNT(*) FROM vr_list_ids)
	
	DECLARE vr_scoreItems FloatStringTableType
	INSERT INTO vr_scoreItems (FirstValue, SecondValue)
	SELECT ref.first_value, ref.second_value
	FROM gfn_str_to_float_string_table(vr_strScoreItems, vr_inner_delimiter, vr_delimiter) AS ref
	
	DECLARE vr_user_ids TABLE (UserID UUID, GroupID UUID)
	
	INSERT INTO vr_user_ids(UserID, GroupID)
	SELECT uid.user_id, CAST(MAX(CAST(uid.group_id AS varchar(50))) AS uuid) AS group_id
	FROM (
			SELECT ref.value AS user_id, NULL AS group_id
			FROM GFN_StrToGuidTable(vr_strUserIDs, vr_delimiter) AS ref	
			
			UNION ALL
			
			SELECT nm.user_id AS user_id, nm.node_id AS group_id
			FROM (
					SELECT ref.value AS value
					FROM vr_node_ids AS ref
					
					UNION ALL
					 
					SELECT nd.node_id
					FROM vr_list_ids AS l_ids
						INNER JOIN cn_list_nodes AS ln
						ON ln.application_id = vr_application_id AND ln.list_id = l_ids.value
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = ln.node_id
					WHERE ln.deleted = FALSE AND nd.deleted = FALSE
				) AS nid
				INNER JOIN cn_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = nid.value
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = nm.user_id
			WHERE nm.status = N'Accepted' AND nm.deleted = FALSE AND un.is_approved = TRUE
		) AS uid
	GROUP BY uid.user_id
	
	IF vr_groups_count = 0 BEGIN
		IF (SELECT COUNT(*) FROM vr_user_ids) = 0 BEGIN
			INSERT INTO vr_user_ids (UserID)
			SELECT UserID
			FROM users_normal
			WHERE ApplicationID = vr_application_id AND is_approved = TRUE
		END
		
		DECLARE vr_dep_type_ids GuidTableType
		INSERT INTO vr_dep_type_ids (Value)
		SELECT ref.node_type_id
		FROM cn_fn_get_department_node_type_ids(vr_application_id) AS ref
	
		UPDATE R
			SET GroupID = ref.group_id
		FROM vr_user_ids AS r
			INNER JOIN (
				SELECT t.user_id,
					CAST(MAX(CAST(nd.node_id AS varchar(36))) AS uuid) AS group_id
				FROM vr_user_ids AS t
					INNER JOIN cn_node_members AS nm
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND 
						nd.node_type_id IN (SELECT Value FROM vr_dep_type_ids) AND nd.deleted = FALSE
					ON nm.application_id = vr_application_id AND
						nm.node_id = nd.node_id AND nm.user_id = t.user_id AND nm.deleted = FALSE
				GROUP BY t.user_id
			) AS ref
			ON r.user_id = ref.user_id
	END
	
	DECLARE vr_knowledge_type_ids GuidTableType
	
	INSERT INTO vr_knowledge_type_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strKnowledgeTypeIDs, vr_delimiter) AS ref
	
	DECLARE vr_user_group_ids GuidPairTableType
	
	INSERT INTO vr_user_group_ids (FirstValue, SecondValue)
	SELECT DISTINCT u.user_id, COALESCE(u.group_id, gen_random_uuid())
	FROM vr_user_ids AS u
	
	EXEC usr_p_users_performance_report vr_application_id, vr_user_group_ids, vr_knowledge_type_ids,
		vr_compensate_per_score, vr_compensation_volume, vr_scoreItems, vr_beginDate, vr_finish_date
END;


DROP PROCEDURE IF EXISTS usr_profile_filled_percentage_report;

CREATE PROCEDURE usr_profile_filled_percentage_report
	vr_application_id		UUID,
	vr_current_user_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	x.filled_percentage,
			COUNT(x.user_id) AS users_count,
			SUM(x.has_job_title) AS job_titles_count,
			SUM(x.jobs_count) AS jobs_count,
			SUM(x.schools_count) AS schools_count,
			SUM(x.courses_count) AS courses_count,
			SUM(x.honors_count) AS honors_count,
			SUM(x.languages_count) AS languages_count
	FROM (
			SELECT	r.user_id,
					(
						CASE WHEN r.has_job_title > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.jobs_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.schools_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.courses_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.honors_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.languages_count > 0 THEN 1 ELSE 0 END
					) * 100 / 6 AS filled_percentage,
					r.has_job_title,
					r.jobs_count,
					r.schools_count,
					r.courses_count,
					r.honors_count,
					r.languages_count
			FROM (
					SELECT	un.user_id,
							CASE WHEN COALESCE(MAX(un.job_title), N'') = N'' THEN 0 ELSE 1 END AS has_job_title,
							COUNT(DISTINCT je.job_id) AS jobs_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 1 THEN ee.education_id 
									ELSE NULL 
								END
							) AS schools_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 0 THEN ee.education_id 
									ELSE NULL 
								END
							) AS courses_count,
							COUNT(DISTINCT ha.id) AS honors_count,
							COUNT(DISTINCT ul.id) AS languages_count
					FROM users_normal AS un
						LEFT JOIN usr_job_experiences AS je
						ON je.application_id = vr_application_id AND 
							je.user_id = un.user_id AND je.deleted = FALSE
						LEFT JOIN usr_educational_experiences AS ee
						ON ee.application_id = vr_application_id AND
							ee.user_id = un.user_id AND ee.deleted = FALSE
						LEFT JOIN usr_honors_and_awards AS ha
						ON ha.application_id = vr_application_id AND
							ha.user_id = un.user_id AND ha.deleted = FALSE
						LEFT JOIN usr_user_languages AS ul
						ON ul.application_id = vr_application_id AND
							ul.user_id = un.user_id AND ul.deleted = FALSE
					WHERE un.application_id = vr_application_id AND un.is_approved = TRUE
					GROUP BY un.user_id
				) AS r
		) AS x
	GROUP BY x.filled_percentage
	
	SELECT ('{' +
			'"FilledPercentage": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "USR", "ReportName": "UsersWithSpecificPercentageOfFilledProfileReport",' +
		   		'"Requires": {"FilledPercentage": {"Value": "FilledPercentage"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_users_with_specific_percentage_of_filled_profile_report;

CREATE PROCEDURE usr_users_with_specific_percentage_of_filled_profile_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_percentage		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	x.user_id AS user_id_hide,
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			x.filled_percentage,
			CASE WHEN x.has_job_title = 1 THEN N'Yes' ELSE N'No' END AS has_job_title_dic,
			x.jobs_count,
			x.schools_count,
			x.courses_count,
			x.honors_count,
			x.languages_count
	FROM (
			SELECT	r.user_id,
					(
						CASE WHEN r.has_job_title > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.jobs_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.schools_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.courses_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.honors_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.languages_count > 0 THEN 1 ELSE 0 END
					) * 100 / 6 AS filled_percentage,
					r.has_job_title,
					r.jobs_count,
					r.schools_count,
					r.courses_count,
					r.honors_count,
					r.languages_count
			FROM (
					SELECT	un.user_id,
							CASE WHEN COALESCE(MAX(un.job_title), N'') = N'' THEN 0 ELSE 1 END AS has_job_title,
							COUNT(DISTINCT je.job_id) AS jobs_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 1 THEN ee.education_id 
									ELSE NULL 
								END
							) AS schools_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 0 THEN ee.education_id 
									ELSE NULL 
								END
							) AS courses_count,
							COUNT(DISTINCT ha.id) AS honors_count,
							COUNT(DISTINCT ul.id) AS languages_count
					FROM users_normal AS un
						LEFT JOIN usr_job_experiences AS je
						ON je.application_id = vr_application_id AND 
							je.user_id = un.user_id AND je.deleted = FALSE
						LEFT JOIN usr_educational_experiences AS ee
						ON ee.application_id = vr_application_id AND
							ee.user_id = un.user_id AND ee.deleted = FALSE
						LEFT JOIN usr_honors_and_awards AS ha
						ON ha.application_id = vr_application_id AND
							ha.user_id = un.user_id AND ha.deleted = FALSE
						LEFT JOIN usr_user_languages AS ul
						ON ul.application_id = vr_application_id AND
							ul.user_id = un.user_id AND ul.deleted = FALSE
					WHERE un.application_id = vr_application_id AND un.is_approved = TRUE
					GROUP BY un.user_id
				) AS r
		) AS x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.user_id
	WHERE (vr_percentage IS NULL OR x.filled_percentage = vr_percentage)
	ORDER BY x.filled_percentage DESC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_job_experience_report;

CREATE PROCEDURE usr_resume_job_experience_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.title, 
			e.employer, 
			e.start_date,
			e.end_date
	FROM usr_job_experiences AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_from) AND
		(vr_date_to IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_to)
	ORDER BY e.user_id ASC, COALESCE(e.start_date, e.end_date) ASC, e.end_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_education_report;

CREATE PROCEDURE usr_resume_education_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.school, 
			e.study_field, 
			(CASE WHEN e.level = N'None' THEN N'' ELSE e.level END) AS level_dic,
			e.start_date,
			e.end_date
	FROM usr_educational_experiences AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND e.is_school = 1 AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_from) AND
		(vr_date_to IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_to)
	ORDER BY e.user_id ASC, COALESCE(e.start_date, e.end_date) ASC, e.end_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_courses_report;

CREATE PROCEDURE usr_resume_courses_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.school, 
			e.study_field, 
			e.start_date,
			e.end_date
	FROM usr_educational_experiences AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND COALESCE(e.is_school, 0) = 0 AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_from) AND
		(vr_date_to IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_to)
	ORDER BY e.user_id ASC, COALESCE(e.start_date, e.end_date) ASC, e.end_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_honors_report;

CREATE PROCEDURE usr_resume_honors_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.title, 
			e.occupation, 
			e.issuer, 
			e.description,
			e.issue_date
	FROM usr_honors_and_awards AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR e.issue_date >= vr_date_from) AND
		(vr_date_to IS NULL OR e.issue_date >= vr_date_to)
	ORDER BY e.user_id ASC, e.issue_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_languages_report;

CREATE PROCEDURE usr_resume_languages_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			l.language_name, 
			e.level AS level_dic
	FROM usr_user_languages AS e
		INNER JOIN usr_language_names AS l
		ON l.application_id = vr_application_id AND l.language_id = l.language_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE)
	ORDER BY e.user_id ASC, l.language_name ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;

DROP PROCEDURE IF EXISTS wf_state_nodes_count_report;

CREATE PROCEDURE wf_state_nodes_count_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_workflow_id				UUID,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT wfs.state_id AS state_id_hide, st.title AS state_title, 
		wfs.workflow_id AS workflow_id_hide, wf.name AS workflow_title, 
		nt.node_type_id AS node_type_id_hide, nt.name AS node_type,
		COALESCE(ref.count, 0) AS count, CAST(st.deleted AS integer) AS removed_state
	FROM (
			SELECT a.state_id, 
				CAST(MAX(CAST(nd.node_type_id AS varchar(36))) AS uuid) AS node_type_id,
				CAST(MAX(CAST(a.workflow_id AS varchar(36))) AS uuid) AS workflow_id,
				COUNT(nd.node_id) AS count
			FROM wf_history AS a
				INNER JOIN (
					SELECT OwnerID, MAX(SendDate) AS send_date
					FROM wf_history
					WHERE ApplicationID = vr_application_id AND deleted = FALSE
					GROUP BY OwnerID
				) AS b
				ON b.owner_id = a.owner_id AND b.send_date = a.send_date
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = a.owner_id
			WHERE a.application_id = vr_application_id AND 
				(vr_workflow_id IS NULL OR a.workflow_id = vr_workflow_id) AND
				(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
				(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit) AND
				 nd.deleted = FALSE
			GROUP BY a.state_id
		) AS ref
		RIGHT JOIN wf_workflow_states AS wfs
		ON wfs.application_id = vr_application_id AND 
			ref.workflow_id = wfs.workflow_id AND wfs.state_id = ref.state_id
		INNER JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = wfs.state_id
		INNER JOIN wf_workflows AS wf
		ON wf.application_id = vr_application_id AND wf.workflow_id = ref.workflow_id
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ref.node_type_id
	WHERE wfs.application_id = vr_application_id AND (ref.state_id IS NOT NULL OR wfs.deleted = FALSE)
	
	
	SELECT ('{' +
			'"Count": {"Action": "Report",' + 
		   		'"ModuleIdentifier": "WF", "ReportName": "NodesWorkFlowStatesReport",' +
		   		'"Requires": {"StateID": {"Value": "StateID_Hide", "Title": "StateTitle"}}, ' + 
		   		'"Params": {"CurrentState": true }' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS wf_nodes_workflow_states_report;

CREATE PROCEDURE wf_nodes_workflow_states_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_tag_id					UUID,
	vr_currentState		 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_results Table (
		NodeID_Hide UUID primary key clustered, 
		Name VARCHAR(1000), 
		AdditionalID varchar(1000), 
		Classification VARCHAR(250),
		UserID_Hide UUID, 
		user VARCHAR(1000), 
		UserName VARCHAR(1000), 
		RefStateID_Hide UUID, 
		RefStateTitle VARCHAR(1000), 
		TagID_Hide UUID, 
		Tag VARCHAR(1000), 
		RefDirectorNodeID_Hide UUID, 
		RefDirectorNode VARCHAR(1000), 
		RefDirectorUserID_Hide UUID, 
		RefDirectorName VARCHAR(1000), 
		RefDirectorUserName VARCHAR(1000), 
		EntranceDate TIMESTAMP, 
		RefSenderUserID_Hide UUID, 
		RefSenderName VARCHAR(1000),
		RefSenderUserName VARCHAR(1000),
		StateID_Hide UUID, 
		StateTitle VARCHAR(1000), 
		DirectorNodeID_Hide UUID, 
		DirectorNodeName VARCHAR(1000),
		DirectorUserID_Hide UUID, 
		DirectorName VARCHAR(1000),
		DirectorUserName VARCHAR(1000),
		SendDate TIMESTAMP, 
		SenderUserID_Hide UUID, 
		SenderName VARCHAR(1000),
		SenderUserName VARCHAR(1000)
	)
	
	INSERT INTO vr_results
	SELECT	rpt.node_id AS node_id_hide, 
			nd.name, 
			nd.additional_id, 
			conf.level AS classification,
			un.user_id AS user_id_hide, 
			(un.first_name + N' ' + un.last_name) AS user, 
			un.username, 
			rpt.ref_state_id AS ref_state_id_hide, 
			rs.title AS ref_state_title, 
			rpt.tag_id AS tag_id_hide, 
			tg.tag, 
			rpt.ref_director_node_id AS ref_director_node_id_hide, 
			rdn.name AS ref_director_node, 
			rpt.ref_director_user_id AS ref_director_user_id_hide, 
			(rdu.first_name + N' ' + rdu.last_name) AS ref_director_name, 
			rdu.username AS ref_director_username, 
			rpt.entrance_date, 
			rpt.ref_sender_user_id AS ref_sender_user_id_hide, 
			(rsu.first_name + N' ' + rsu.last_name) AS ref_sender_name,
			rsu.username AS ref_sender_username,
			rpt.state_id AS state_id_hide, 
			st.title AS state_title, 
			rpt.director_node_id AS director_node_id_hide, 
			dn.name AS director_node_name,
			rpt.director_user_id AS director_user_id_hide, 
			(du.first_name + N' ' + du.last_name) AS director_name,
			du.username AS director_username,
			rpt.send_date, 
			rpt.sender_user_id AS sender_user_id_hide, 
			(su.first_name + N' ' + su.last_name) AS sender_name,
			su.username AS sender_username
	FROM (
			SELECT ref.node_id AS node_id, 
				CAST(MAX(CAST(ref.state_id AS varchar(36))) AS uuid) AS ref_state_id,
				CAST(MAX(CAST(ref.tag_id AS varchar(36))) AS uuid) AS tag_id,
				CAST(MAX(CAST(ref.director_node_id AS varchar(36))) AS uuid) AS ref_director_node_id,
				CAST(MAX(CAST(ref.director_user_id AS varchar(36))) AS uuid) AS ref_director_user_id,
				MAX(ref.send_date) AS entrance_date, 
				CAST(MAX(CAST(ref.sender_user_id AS varchar(36))) AS uuid) AS ref_sender_user_id,
				CAST(MAX(CAST(h.state_id AS varchar(36))) AS uuid) AS state_id,
				CAST(MAX(CAST(h.director_node_id AS varchar(36))) AS uuid) AS director_node_id,
				CAST(MAX(CAST(h.director_user_id AS varchar(36))) AS uuid) AS director_user_id,
				MAX(h.send_date) AS send_date,
				CAST(MAX(CAST(h.sender_user_id AS varchar(36))) AS uuid) AS sender_user_id
			FROM (
					SELECT a.owner_id AS node_id, a.workflow_id, a.state_id AS state_id, b.tag_id AS tag_id, 
						a.director_node_id, a.director_user_id, b.send_date, a.sender_user_id
					FROM wf_history AS a
						INNER JOIN (
							SELECT h.owner_id, MAX(h.send_date) AS send_date, 
								CAST(MAX(CAST(wfs.tag_id AS varchar(36))) AS uuid) AS tag_id
							FROM wf_history AS h
								INNER JOIN wf_workflow_states AS wfs
								ON wfs.application_id = vr_application_id AND 
									h.workflow_id = wfs.workflow_id AND wfs.state_id = h.state_id
							WHERE h.application_id = vr_application_id AND 
								(vr_workflow_id IS NULL OR h.workflow_id = vr_workflow_id) AND
								(vr_stateID IS NULL OR h.state_id = vr_stateID) AND
								(vr_tag_id IS NULL OR wfs.tag_id = vr_tag_id) AND h.deleted = FALSE
							GROUP BY h.owner_id
						) AS b
						ON b.owner_id = a.owner_id AND a.send_date = b.send_date
					WHERE a.application_id = vr_application_id
				) AS ref
				LEFT JOIN wf_history AS h
				ON h.application_id = vr_application_id AND h.owner_id = ref.node_id AND 
					h.workflow_id = ref.workflow_id AND h.send_date > ref.send_date
			WHERE (vr_currentState IS NULL OR (vr_currentState = 1 AND h.send_date IS NULL) OR 
				vr_currentState = 0 AND h.send_date IS NOT NULL)
			GROUP BY ref.node_id
		) AS rpt
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rpt.node_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
		LEFT JOIN wf_states AS rs
		ON rs.application_id = vr_application_id AND rs.state_id = rpt.ref_state_id
		LEFT JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = rpt.tag_id
		LEFT JOIN cn_nodes AS rdn
		ON rdn.application_id = vr_application_id AND rdn.node_id = rpt.ref_director_node_id
		LEFT JOIN users_normal AS rdu
		ON rdu.application_id = vr_application_id AND rdu.user_id = rpt.ref_director_user_id
		LEFT JOIN users_normal AS rsu
		ON rsu.application_id = vr_application_id AND rsu.user_id = rpt.ref_sender_user_id
		LEFT JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = rpt.state_id
		LEFT JOIN cn_nodes AS dn
		ON dn.application_id = vr_application_id AND dn.node_id = rpt.director_node_id
		LEFT JOIN users_normal AS du
		ON du.application_id = vr_application_id AND du.user_id = rpt.director_user_id
		LEFT JOIN users_normal AS su
		ON su.application_id = vr_application_id AND su.user_id = rpt.sender_user_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
		(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit) AND
		nd.deleted = FALSE
		
	SELECT *
	FROM vr_results
		
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"User": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"RefDirectorNode": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "RefDirectorNodeID_Hide"}' +
			'},' +
			'"RefDirectorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "RefDirectorUserID_Hide"}' +
			'},' +
			'"RefSenderName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "RefSenderUserID_Hide"}' +
			'},' +
			'"DirectorNodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DirectorNodeID_Hide"}' +
			'},' +
			'"DirectorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "DirectorUserID_Hide"}' +
			'},' +
			'"SenderName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "SenderUserID_Hide"}' +
			'}' +
		   '}') AS actions
		   
	IF vr_nodeTypeID IS NOT NULL BEGIN
		DECLARE vr_form_id UUID = (
			SELECT TOP(1) FormID
			FROM fg_form_owners
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_nodeTypeID AND deleted = FALSE
		)
		
		IF vr_form_id IS NOT NULL AND EXISTS(
			SELECT TOP(1) *
			FROM cn_extensions AS ex
			WHERE ex.application_id = vr_application_id AND 
				ex.owner_id = vr_nodeTypeID AND ex.extension = N'Form' AND ex.deleted = FALSE
		) BEGIN
			-- Second Part: Describes the Third Part
			SELECT CAST(efe.element_id AS varchar(50)) AS column_name, efe.title AS translation,
				CASE
					WHEN efe.type = N'Binary' THEN N'bool'
					WHEN efe.type = N'Number' THEN N'double'
					WHEN efe.type = N'Date' THEN N'datetime'
					WHEN efe.type = N'User' THEN N'user'
					WHEN efe.type = N'Node' THEN N'node'
					ELSE N'string'
				END AS type
			FROM fg_extended_form_elements AS efe
			WHERE efe.application_id = vr_application_id AND 
				efe.form_id = vr_form_id AND efe.deleted = FALSE
			ORDER BY efe.sequence_number ASC
			
			SELECT ('{"IsDescription": "true"}') AS info
			-- end of Second Part
			
			-- Third Part: The Form Info
			DECLARE vr_node_ids GuidTableType
			
			INSERT INTO vr_node_ids (Value)
			SELECT r.node_id_hide
			FROM vr_results AS r
			
			DECLARE vr_element_ids GuidTableType
			
			DECLARE vr_fake_instances GuidTableType
			DECLARE vr_fake_filters FormFilterTableType
			
			EXEC fg_p_get_form_records vr_application_id, vr_form_id, 
				vr_element_ids, vr_fake_instances, vr_node_ids, 
				vr_fake_filters, NULL, 1000000, NULL, NULL
			
			SELECT ('{' +
				'"ColumnsMap": "NodeID_Hide:OwnerID",' +
				'"ColumnsToTransfer": "' + STUFF((
					SELECT ',' + CAST(efe.element_id AS varchar(50))
					FROM fg_extended_form_elements AS efe
					WHERE efe.application_id = vr_application_id AND 
						efe.form_id = vr_form_id AND efe.deleted = FALSE
					ORDER BY efe.sequence_number ASC
					FOR xml path('a'), type
				).value('.','nvarchar(max)'), 1, 1, '') + '"' +
			   '}') AS info
			-- End of Third Part
		END
	END
END;


DROP PROCEDURE IF EXISTS kw_knowledge_admins_report;

CREATE PROCEDURE kw_knowledge_admins_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	d.user_id AS user_id_hide,
			MAX(un.first_name + N' ' + un.last_name) AS full_name,
			COUNT(d.id) AS items_count,
			SUM(CASE WHEN d.deleted = FALSE AND d.action_date IS NULL THEN 1 ELSE 0 END) AS pending_count,
			SUM(CASE WHEN d.action_date IS NULL THEN 0 ELSE 1 END) AS done_count,
			SUM(CASE WHEN d.seen = 0 THEN 1 ELSE 0 END) AS not_seen_count, 
			AVG(
				CASE
					WHEN d.action_date IS NULL THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_max,
			AVG(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_max
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Admin' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from) AND
		(vr_delay_to IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen)
	GROUP BY d.user_id

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"PendingCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeAdminsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "false"}' + 
		   	'},' +
		   	'"DoneCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeAdminsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "true"}' + 
		   	'},' +
		   	'"NotSeenCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeAdminsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Seen": "false"}' + 
		   	'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_admins_detail_report;

CREATE PROCEDURE kw_knowledge_admins_detail_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
	vr_knowledge_id			UUID,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	nd.node_id AS node_id_hide,
			nd.node_name,
			nd.type_name AS node_type,
			d.user_id AS user_id_hide,
			un.first_name + N' ' + un.last_name AS full_name,
			d.send_date,
			d.action_date,
			CASE
				WHEN d.deleted = FALSE AND d.action_date IS NULL THEN N'Pending'
				WHEN d.action_date IS NOT NULL THEN N'Done'
				ELSE N''
			END AS done_status_dic,
			CASE WHEN d.seen = 0 THEN N'Seen' ELSE N'NotSeen' END AS seen_status_dic, 
			CASE
				WHEN d.deleted IS NULL THEN 0
				ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) AS integer) / (24 * 3600), 0)
			END AS action_delay
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Admin' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from)) AND
		(vr_delay_to IS NULL OR  (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to)) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen) AND
		(vr_knowledge_id IS NULL OR nd.node_id = vr_knowledge_id)

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_evaluations_report;

CREATE PROCEDURE kw_knowledge_evaluations_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN,
	vr_canceled			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	d.user_id AS user_id_hide,
			MAX(un.first_name + N' ' + un.last_name) AS full_name,
			COUNT(d.id) AS items_count,
			SUM(CASE WHEN d.deleted = FALSE AND d.action_date IS NULL THEN 1 ELSE 0 END) AS pending_count,
			SUM(CASE WHEN d.action_date IS NULL THEN 0 ELSE 1 END) AS evaluations_count,
			SUM(CASE WHEN d.deleted = TRUE THEN 1 ELSE 0 END) AS canceled_count,
			SUM(CASE WHEN d.seen = 0 THEN 1 ELSE 0 END) AS not_seen_count, 
			AVG(
				CASE
					WHEN d.action_date IS NULL THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_max,
			AVG(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_max
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Evaluator' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from) AND
		(vr_delay_to IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen) AND
		(vr_canceled IS NULL OR d.deleted = vr_canceled)
	GROUP BY d.user_id

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"PendingCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "false"}' + 
		   	'},' +
		   	'"EvaluationsCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "true"}' + 
		   	'},' +
		   	'"CanceledCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Canceled": "true"}' + 
		   	'},' +
		   	'"NotSeenCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Seen": "false"}' + 
		   	'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_evaluations_detail_report;

CREATE PROCEDURE kw_knowledge_evaluations_detail_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
	vr_knowledge_id			UUID,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN,
	vr_canceled			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	nd.node_id AS node_id_hide,
			nd.node_name,
			nd.type_name AS node_type,
			d.user_id AS user_id_hide,
			un.first_name + N' ' + un.last_name AS full_name,
			d.send_date,
			d.action_date,
			CASE
				WHEN d.deleted = FALSE AND d.action_date IS NULL THEN N'Pending'
				WHEN d.deleted = TRUE THEN N'Canceled'
				WHEN d.action_date IS NOT NULL THEN N'Done'
				ELSE N''
			END AS evaluation_status_dic,
			CASE WHEN d.seen = 0 THEN N'Seen' ELSE N'NotSeen' END AS seen_status_dic, 
			CASE
				WHEN d.deleted IS NULL THEN 0
				ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) AS integer) / (24 * 3600), 0)
			END AS evaluation_delay
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Evaluator' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from)) AND
		(vr_delay_to IS NULL OR  (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to)) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen) AND
		(vr_canceled IS NULL OR d.deleted = vr_canceled) AND
		(vr_knowledge_id IS NULL OR nd.node_id = vr_knowledge_id)

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_evaluations_history_report;

CREATE PROCEDURE kw_knowledge_evaluations_history_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_knowledge_id		UUID,
	vr_strUserIDs			varchar(max),
	vr_delimiter			char,
	vr_date_from		 TIMESTAMP,
	vr_date_to			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_usersIDsCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	
	DECLARE vr_last_versions TABLE (KnowledgeID UUID primary key clustered, LastVersionID INTEGER)

	INSERT INTO vr_last_versions (KnowledgeID, LastVersionID)
	SELECT h.knowledge_id, MAX(h.wf_version_id) AS last_version_id
	FROM kw_history AS h
	GROUP BY h.knowledge_id


	DECLARE vr_ret TABLE (
		NodeID_Hide UUID, 
		NodeName VARCHAR(1000), 
		NodeAdditionalID VARCHAR(100),
		NodeType VARCHAR(200),
		CreatorUserID_Hide UUID,
		CreatorFullName VARCHAR(200),
		CreatorUserName VARCHAR(100),
		Status_Dic VARCHAR(100),
		EvaluatorUserID_Hide UUID,
		EvaluatorFullName VARCHAR(200),
		EvaluatorUserName VARCHAR(100),
		Score float,
		EvaluationDate TIMESTAMP,
		WFVersionID INTEGER,
		description VARCHAR(max),
		Reasons VARCHAR(1000)
	)


	INSERT INTO vr_ret (NodeID_Hide, NodeName, NodeAdditionalID, NodeType, CreatorUserID_Hide, CreatorUserName, CreatorFullName, 
		Status_Dic, EvaluatorUserID_Hide, EvaluatorUserName, EvaluatorFullName, Score, EvaluationDate, WFVersionID, 
		description, Reasons)
	SELECT	nd.node_id, nd.node_name, nd.node_additional_id, nd.type_name, un.user_id, un.username, 
		LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))),
		nd.status, x.evaluator_user_id, x.evaluator_username,
		LTRIM(RTRIM(COALESCE(x.evaluator_first_name, N'') + N' ' + COALESCE(x.evaluator_last_name, N''))),
		x.score, x.evaluation_date, x.wf_version_id, h.description, h.text_options
	FROM (
			SELECT	ref.knowledge_id,
					ref.user_id AS evaluator_user_id,
					un.username AS evaluator_username,
					un.first_name AS evaluator_first_name,
					un.last_name AS evaluator_last_name,
					ref.score,
					ref.evaluation_date,
					lv.last_version_id AS wf_version_id
			FROM (
					SELECT	a.knowledge_id, 
							a.user_id, 
							(SUM(COALESCE(COALESCE(a.admin_score, a.score), 0)) / COALESCE(COUNT(a.user_id), 1)) AS score,
							MAX(a.evaluation_date) AS evaluation_date
					FROM kw_question_answers AS a
					WHERE a.application_id = vr_application_id AND a.deleted = FALSE AND
						(vr_date_from IS NULL OR a.evaluation_date > vr_date_from) AND
						(vr_date_to IS NULL OR a.evaluation_date <= vr_date_to)
					GROUP BY a.knowledge_id, a.user_id
				) AS ref
				INNER JOIN vr_last_versions AS lv
				ON lv.knowledge_id = ref.knowledge_id
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.user_id AND
					(vr_usersIDsCount = 0 OR un.user_id IN (SELECT Value FROM vr_user_ids))

			UNION ALL

			SELECT	ref.knowledge_id,
					ref.user_id,
					un.username,
					un.first_name,
					un.last_name,
					ref.score,
					ref.evaluation_date,
					ref.wf_version_id
			FROM (
					SELECT a.knowledge_id, a.user_id, (SUM(COALESCE(COALESCE(a.admin_score, a.score), 0)) / COALESCE(COUNT(a.user_id), 1)) AS score,
						MAX(a.evaluation_date) AS evaluation_date, a.wf_version_id
					FROM kw_question_answers_history AS a
					WHERE a.application_id = vr_application_id AND a.deleted = FALSE AND
						(vr_date_from IS NULL OR a.evaluation_date > vr_date_from) AND
						(vr_date_to IS NULL OR a.evaluation_date <= vr_date_to)
					GROUP BY a.knowledge_id, a.user_id, a.wf_version_id
				) AS ref
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.user_id AND
					(vr_usersIDsCount = 0 OR un.user_id IN (SELECT Value FROM vr_user_ids))
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.knowledge_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id) AND
			(vr_knowledge_id IS NULL OR nd.node_id = vr_knowledge_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
		LEFT JOIN kw_history AS h
		ON h.application_id = vr_application_id AND h.knowledge_id = x.knowledge_id AND 
			h.actor_user_id = x.evaluator_user_id AND h.action_date = x.evaluation_date
	ORDER BY x.evaluation_date DESC, x.knowledge_id DESC, x.wf_version_id DESC

	SELECT *
	FROM vr_ret


	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"CreatorFullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'},' +
			'"EvaluatorFullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "EvaluatorUserID_Hide"}' +
			'},' +
			'"Contributor": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "ContributorID_Hide"}' +
			'}' +
		   '}') AS actions
		   
	   
	-- Add Contributor Columns

	DECLARE vr_proc VARCHAR(max) = N''

	SELECT x.*
	INTO #Result
	FROM (
			SELECT	c.node_id, 
					CAST(c.user_id AS varchar(50)) AS unq,
					c.user_id, 
					c.collaboration_share AS share,
					ROW_NUMBER() OVER (PARTITION BY c.node_id ORDER BY c.collaboration_share DESC, c.user_id DESC) AS row_number
			FROM vr_ret AS i_ds
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND c.node_id = i_ds.node_id_hide AND c.deleted = FALSE
		) AS x
		
	DECLARE vr_count INTEGER = (SELECT MAX(RowNumber) FROM #Result)
	DECLARE vr_itemsList varchar(max) = N'', vr_selectList varchar(max) = N'', vr_cols_to_transfer varchar(max) = N''

	SET vr_proc = N''

	DECLARE vr_ind INTEGER = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_tmp varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_selectList = vr_selectList + '[' + vr_tmp + '] AS contributor_id_hide_' + vr_tmp + '], ' + 
			'CAST(NULL AS varchar(500)) AS contributor_' + vr_tmp + '], ' +
			'CAST(NULL AS float) AS contributor_share_' + vr_tmp + ']'
			
		SET vr_itemsList = vr_itemsList + '[' + vr_tmp + ']'
		
		SET vr_proc = vr_proc + 
			'SELECT ''ContributorID_Hide_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''Contributor_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''ContributorShare_' + vr_tmp + ''' AS column_name, null AS translation, ''double'' AS type '
			
		SET vr_cols_to_transfer = vr_cols_to_transfer + 
			'ContributorID_Hide_' + vr_tmp + ',Contributor_' + vr_tmp + ',ContributorShare_' + vr_tmp
		
		IF vr_ind > 0 BEGIN 
			SET vr_selectList = vr_selectList + ', '
			SET vr_itemsList = vr_itemsList + ', '
			SET vr_proc = vr_proc + N'UNION ALL '
			SET vr_cols_to_transfer = vr_cols_to_transfer + ','
		END
		
		SET vr_ind = vr_ind - 1
	END

	-- Second Part: Describes the Third Part
	EXEC (vr_proc)

	SELECT ('{"IsDescription": "true"}') AS info
	-- end of Second Part

	-- Third Part: The Data
	SET vr_proc = 
		'SELECT NodeID AS node_id_hide, ' + vr_selectList + 
		'INTO #Final ' +
		'FROM ( ' +
				'SELECT NodeID, unq, RowNumber ' +
				'FROM #Result ' +
			') AS p ' +
			'PIVOT (MAX(unq) FOR RowNumber IN (' + vr_itemsList + ')) AS pvt '

	SET vr_ind = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_no varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET Contributor_' + vr_no + ' = LTRIM(RTRIM(COALESCE(un.first_name, N'''') + N'' '' + COALESCE(un.last_name, N''''))) ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN users_normal AS un ' + 
				'ON un.application_id = ''' + CAST(vr_application_id AS varchar(50)) + ''' AND un.user_id = f.contributor_id_hide_' + vr_no + ' '
				
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET ContributorShare_' + vr_no + ' = r.share ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN #Result AS r ' + 
				'ON r.node_id = f.node_id_hide AND r.user_id = f.contributor_id_hide_' + vr_no + ' '
		
		SET vr_ind = vr_ind - 1
	END

	SET vr_proc = vr_proc + 'SELECT * FROM #Final'

	EXEC (vr_proc)

	SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:NodeID_Hide",' +
			'"ColumnsToTransfer": "' + vr_cols_to_transfer + '"' +
		   '}') AS info
	-- end of Third Part

	-- end of Add Contributor Columns
END;