DROP FUNCTION IF EXISTS fg_save_form_elements;

CREATE OR REPLACE FUNCTION fg_save_form_elements
(
	vr_application_id	UUID,
	vr_form_id			UUID,
	vr_title		 	VARCHAR(255),
	vr_name				VARCHAR(100),
	vr_description 		VARCHAR(2000),
	vr_elements			form_element_table_type[],
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	-- Update Form
	vr_title := gfn_verify_string(LTRIM(RTRIM(COALESCE(vr_title, ''))));
	vr_name := LTRIM(RTRIM(COALESCE(vr_name, '')));
	vr_description := gfn_verify_string(LTRIM(RTRIM(COALESCE(vr_description, N''))));
	
	UPDATE fg_extended_forms AS f
	SET title = CASE WHEN vr_title = '' THEN f.title ELSE vr_title END,
		"name" = CASE WHEN vr_name = '' THEN f.name ELSE vr_name END,
		description = CASE WHEN vr_description = '' THEN f.description ELSE vr_description END
	WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id;
	-- end of Update Form
	
	
	-- Update Existing Data
	UPDATE X
	SET	title = CASE WHEN e.element_id IS NULL THEN x.title ELSE e.title END,
		"info" = CASE WHEN e.element_id IS NULL THEN x.info ELSE e.info END,
		sequence_number = CASE WHEN e.element_id IS NULL THEN x.sequence_number ELSE e.sequence_nubmer END,
		last_modifier_user_id = CASE WHEN e.element_id IS NULL THEN x.last_modifier_user_id ELSE vr_current_user_id END,
		last_modification_date = CASE WHEN e.element_id IS NULL THEN x.last_modification_date ELSE vr_now END,
		deleted = CASE WHEN e.element_id IS NULL THEN TRUE ELSE FALSE END,
		necessary = CASE WHEN e.element_id IS NULL THEN x.necessary ELSE e.necessary END,
		weight = CASE WHEN e.element_id IS NULL THEN x.weight ELSE e.weight END,
		"name" = CASE WHEN e.element_id IS NULL THEN x.name ELSE e.name END,
		unique_value = CASE WHEN e.element_id IS NULL THEN x.unique_value ELSE e.unique_value END,
		help = CASE WHEN e.element_id IS NULL THEN x.help ELSE e.help END
	FROM fg_extended_form_elements AS x
		LEFT JOIN UNNEST(vr_elements) AS e
		ON e.element_id = x.element_id
	WHERE x.application_id = vr_application_id AND x.form_id = vr_form_id;
	-- end of Update Existing Data
	
	-- Insert New Data
	INSERT INTO fg_extended_form_elements (
		application_id,
		element_id,
		template_element_id,
		form_id,
		title,
		"type",
		"info",
		sequence_number,
		creator_user_id,
		creation_date,
		deleted,
		necessary,
		weight,
		"name",
		unique_value,
		help
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
			FALSE,
			e.necessary,
			e.weight,
			e.name,
			e.unique_value,
			e.help
	FROM UNNEST(vr_elements) AS e
		LEFT JOIN fg_extended_form_elements AS x
		ON x.application_id = vr_application_id AND x.element_id = e.element_id
	WHERE x.element_id IS NULL;
	-- end of Insert New Data
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

