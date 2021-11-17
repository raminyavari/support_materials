DROP FUNCTION IF EXISTS usr_set_main_email;

CREATE OR REPLACE FUNCTION usr_set_main_email
(
	vr_email_id			UUID,
	vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET main_email_id = vr_email_id
	WHERE pr.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

