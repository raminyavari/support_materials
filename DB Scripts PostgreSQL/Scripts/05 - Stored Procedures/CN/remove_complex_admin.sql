DROP FUNCTION IF EXISTS cn_remove_complex_admin;

CREATE OR REPLACE FUNCTION cn_remove_complex_admin
(
	vr_application_id	UUID,
	vr_list_id			UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_list_admins AS x
	SET last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		 deleted = TRUE
	WHERE x.application_id = vr_application_id AND x.list_id = vr_list_id AND x.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

