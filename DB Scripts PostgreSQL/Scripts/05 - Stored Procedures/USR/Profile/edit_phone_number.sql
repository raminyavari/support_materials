DROP FUNCTION IF EXISTS usr_edit_phone_number;

CREATE OR REPLACE FUNCTION usr_edit_phone_number
(
	vr_number_id		UUID,
	vr_phone_number		VARCHAR(50),
	vr_phone_type		VARCHAR(20),
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_phone_numbers AS pn
	SET phone_number = vr_phone_number,
		phone_type = vr_phone_type,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE pn.number_id = vr_number_id AND deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

