DROP FUNCTION IF EXISTS fg_add_poll;

CREATE OR REPLACE FUNCTION fg_add_poll
(
	vr_application_id		UUID,
	vr_poll_id				UUID,
	vr_copy_from_poll_id	UUID,
	vr_owner_id				UUID,
	vr_name		 			VARCHAR(255),
	vr_current_user_id		UUID,
	vr_now		 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN fg_p_add_poll(vr_application_id, vr_poll_id, vr_copy_from_poll_id, 
						 vr_owner_id, vr_name, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;

