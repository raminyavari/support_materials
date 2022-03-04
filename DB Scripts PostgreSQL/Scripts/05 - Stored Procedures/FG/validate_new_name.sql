DROP FUNCTION IF EXISTS fg_validate_new_name;

CREATE OR REPLACE FUNCTION fg_validate_new_name
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
	RETURN fg_fn_validate_new_name(vr_application_id, vr_object_id, vr_form_id, vr_name);
END;
$$ LANGUAGE plpgsql;

