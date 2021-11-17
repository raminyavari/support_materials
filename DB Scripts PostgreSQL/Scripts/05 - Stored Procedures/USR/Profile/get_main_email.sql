DROP FUNCTION IF EXISTS usr_get_main_email;

CREATE OR REPLACE FUNCTION usr_get_main_email
(
	vr_user_id		UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT pr.main_email_id AS "id"
		FROM usr_profile AS pr
		WHERE pr.user_id = vr_user_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

