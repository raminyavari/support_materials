DROP FUNCTION IF EXISTS usr_get_current_password;

CREATE OR REPLACE FUNCTION usr_get_current_password
(
	vr_user_id 	UUID
)
RETURNS TABLE (
	"password"		VARCHAR, 
	password_salt	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	"m".password, 
			"m".password_salt
	FROM rv_membership AS "m"
	WHERE "m".user_id = vr_user_id
	LIMIT 1;
END;
$$ LANGUAGE plpgsql;

