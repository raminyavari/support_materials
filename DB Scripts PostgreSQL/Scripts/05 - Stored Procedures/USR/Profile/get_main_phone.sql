DROP FUNCTION IF EXISTS usr_get_main_phone;

CREATE OR REPLACE FUNCTION usr_get_main_phone
(
	vr_user_id		UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT pr.main_phone_id AS "id"
		FROM usr_profile AS pr
		WHERE pr.user_id = vr_user_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

