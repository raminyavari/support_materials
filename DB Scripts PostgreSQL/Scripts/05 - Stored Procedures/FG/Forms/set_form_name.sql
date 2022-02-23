DROP FUNCTION IF EXISTS fg_set_form_name;

CREATE OR REPLACE FUNCTION fg_set_form_name
(
	vr_application_id	UUID,
    vr_form_id			UUID,
    vr_name				VARCHAR(100),
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(vr_name, '') <> '' AND EXISTS (
		SELECT 1
		FROM fg_extended_forms AS f
		WHERE f.application_id = vr_application_id AND f.deleted = FALSE AND 
			LOWER(f.name) = LOWER(vr_name) AND f.form_id <> vr_form_id
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'NameAlreadyExists');
		RETURN -1;
	END IF;
	
	UPDATE fg_extended_forms AS f
	SET "name" = vr_name,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

