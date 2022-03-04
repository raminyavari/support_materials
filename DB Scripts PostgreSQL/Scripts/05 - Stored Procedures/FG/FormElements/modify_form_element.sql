DROP FUNCTION IF EXISTS fg_modify_form_element;

CREATE OR REPLACE FUNCTION fg_modify_form_element
(
	vr_application_id		UUID,
	vr_element_id			UUID,
	vr_title				VARCHAR(2000),
	vr_name					VARCHAR(100),
	vr_help			 		VARCHAR(2000),
	vr_info			 		VARCHAR,
	vr_weight				FLOAT,
	vr_current_user_id		UUID,
	vr_now	 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_form_id	UUID;
	vr_result	INTEGER;
BEGIN
	vr_form_id := (
		SELECT e.form_id
		FROM fg_extended_form_elements AS e
		WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id
		LIMIT 1
	);
	
	IF COALESCE(vr_name, '') <> '' AND EXISTS (
		SELECT 1
		FROM fg_extended_form_elements AS f
		WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id AND f.deleted = FALSE AND 
			LOWER(f.name) = LOWER(vr_name) AND f.element_id <> vr_element_id
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'NameAlreadyExists');
		RETURN -1;
	END IF;
	
	UPDATE fg_extended_form_elements AS e
	SET title = gfn_verify_string(vr_title),
		"name" = vr_name,
		help = gfn_verify_string(vr_help),
		"info" = vr_info,
		weight = vr_weight,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

