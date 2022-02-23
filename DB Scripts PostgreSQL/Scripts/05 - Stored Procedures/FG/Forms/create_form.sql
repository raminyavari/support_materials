DROP FUNCTION IF EXISTS fg_create_form;

CREATE OR REPLACE FUNCTION fg_create_form
(
	vr_application_id	UUID,
    vr_form_id			UUID,
    vr_template_form_id	UUID,
	vr_title			VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN fg_p_create_form(vr_application_id, vr_form_id, vr_template_form_id,
							vr_title, vr_creator_user_id, vr_creation_date);
END;
$$ LANGUAGE plpgsql;

