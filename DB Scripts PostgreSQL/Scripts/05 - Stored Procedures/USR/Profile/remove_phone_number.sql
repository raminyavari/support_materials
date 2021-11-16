DROP FUNCTION IF EXISTS usr_remove_phone_number;

CREATE OR REPLACE FUNCTION usr_remove_phone_number
(
	vr_number_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET main_phone_id = null
	WHERE pr.main_phone_id = vr_number_id;

	UPDATE usr_phone_numbers AS pn
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE pn.number_id = vr_number_id AND deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

