DROP FUNCTION IF EXISTS fg_set_form_owner;

CREATE OR REPLACE FUNCTION fg_set_form_owner
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN fg_p_set_form_owner(vr_application_id, vr_owner_id, vr_form_id, 
							   vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;

