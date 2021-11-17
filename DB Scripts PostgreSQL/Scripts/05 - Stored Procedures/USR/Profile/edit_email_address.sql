DROP FUNCTION IF EXISTS usr_edit_email_address;

CREATE OR REPLACE FUNCTION usr_edit_email_address
(
	vr_email_id			UUID,
	vr_address			VARCHAR(100),
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_email_addresses AS ea
	SET email_address = vr_address,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE ea.email_id = vr_email_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

