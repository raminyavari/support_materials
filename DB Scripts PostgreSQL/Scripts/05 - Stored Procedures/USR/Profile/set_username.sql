DROP FUNCTION IF EXISTS usr_set_username;

CREATE OR REPLACE FUNCTION usr_set_username
(
	vr_application_id	UUID,
    vr_user_id 			UUID,
    vr_username	 		VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(vr_username, '') <> '' AND NOT EXISTS (
		SELECT 1 
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND 
			un.lowered_username = LOWER(vr_username) AND un.user_id <> vr_user_id
		LIMIT 1
	) THEN
		UPDATE rv_users AS u
		SET username = vr_username,
			lowered_username = LOWER(vr_username)
		WHERE u.user_id = vr_user_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	ELSE
		RETURN 1::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;

