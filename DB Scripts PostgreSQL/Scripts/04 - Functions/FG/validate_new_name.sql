DROP FUNCTION IF EXISTS fg_fn_validate_new_name;

CREATE OR REPLACE FUNCTION fg_fn_validate_new_name
(
	vr_application_id	UUID,
	vr_object_id		UUID,
	vr_form_id			UUID,
	vr_name				VARCHAR(100)
)
RETURNS BOOLEAN
AS
$$
BEGIN
	vr_name := LOWER(LTRIM(RTRIM(COALESCE(vr_name, ''))));
	
	IF vr_name = '' OR vr_object_id IS NULL THEN
		RETURN FALSE;
	END IF;

	IF vr_form_id IS NULL THEN
		RETURN COALESCE((
			SELECT FALSE
			FROM fg_extended_forms AS f
			WHERE f.application_id = vr_application_id AND f.deleted = FALSE AND
				f.form_id <> vr_object_id AND LOWER(f.name) = vr_name
			LIMIT 1
		), TRUE);
	ELSE
		RETURN COALESCE((
			SELECT FALSE
			FROM fg_extended_form_elements AS e
			WHERE e.application_id = vr_application_id AND e.form_id = vr_form_id AND e.deleted = FALSE AND
				e.element_id <> vr_object_id AND LOWER(e.name) = vr_name
			LIMIT 1
		), TRUE);
	END IF;
END;
$$ LANGUAGE PLPGSQL;