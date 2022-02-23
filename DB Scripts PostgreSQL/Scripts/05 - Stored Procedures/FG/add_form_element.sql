DROP FUNCTION IF EXISTS fg_add_form_element;

CREATE OR REPLACE FUNCTION fg_add_form_element
(
	vr_application_id		UUID,
	vr_element_id			UUID,
	vr_template_element_id	UUID,
	vr_form_id				UUID,
	vr_title				VARCHAR(2000),
	vr_name					VARCHAR(100),
	vr_help			 		VARCHAR(2000),
	vr_sequence_number		INTEGER,
	vr_type					VARCHAR(20),
	vr_info			 		VARCHAR,
	vr_current_user_id		UUID,
	vr_now	 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(vr_name, '') <> '' AND EXISTS (
		SELECT 1
		FROM fg_extended_form_elements AS f
		WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id AND 
			f.deleted = FALSE AND LOWER(f.name) = LOWER(vr_name)
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'NameAlreadyExists');
		RETURN -1;
	END IF;
	
	INSERT INTO fg_extended_form_elements (
		application_id,
		element_id,
		template_element_id,
		form_id,
		title,
		"name",
		help,
		sequence_number,
		"type",
		"info",
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_element_id,
		vr_template_element_id,
		vr_form_id,
		gfn_verify_string(vr_title),
		vr_name,
		gfn_verify_string(vr_help),
		vr_sequence_number,
		vr_type,
		vr_info,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

