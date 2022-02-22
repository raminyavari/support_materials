
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