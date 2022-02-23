DROP FUNCTION IF EXISTS fg_recycle_form;

CREATE OR REPLACE FUNCTION fg_recycle_form
(
	vr_application_id	UUID,
    vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_extended_forms AS f
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

