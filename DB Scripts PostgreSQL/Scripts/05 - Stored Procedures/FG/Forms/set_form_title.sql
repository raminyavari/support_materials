DROP FUNCTION IF EXISTS fg_set_form_title;

CREATE OR REPLACE FUNCTION fg_set_form_title
(
	vr_application_id	UUID,
    vr_form_id			UUID,
	vr_title			VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM fg_extended_forms AS f
		WHERE f.application_id = vr_application_id AND 
			f.title = vr_title AND f.form_id <> vr_form_id AND f.deleted = FALSE
		LIMIT 1
	) THEN
		vr_result := -1;
	ELSE
		UPDATE fg_extended_forms AS f
		SET title = gfn_verify_string(vr_title),
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id;

		GET DIAGNOSTICS vr_result := ROW_COUNT;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

