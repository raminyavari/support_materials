DROP FUNCTION IF EXISTS usr_set_verification_code_media;

CREATE OR REPLACE FUNCTION usr_set_verification_code_media
(
	vr_user_id	UUID,
	vr_media	VARCHAR(50)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET two_step_authentication = vr_media
	WHERE pr.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

