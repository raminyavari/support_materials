DROP FUNCTION IF EXISTS fg_set_form_instance_as_filled;

CREATE OR REPLACE FUNCTION fg_set_form_instance_as_filled
(
	vr_application_id	UUID,
	vr_instance_id		UUID,
	vr_now	 			TIMESTAMP,
	vr_current_user_id	UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN fg_p_set_form_instance_as_filled(vr_application_id, vr_instance_id, vr_now, vr_current_user_id);
END;
$$ LANGUAGE plpgsql;

