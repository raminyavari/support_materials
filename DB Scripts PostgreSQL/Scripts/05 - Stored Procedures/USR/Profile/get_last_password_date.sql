DROP FUNCTION IF EXISTS usr_get_last_password_date;

CREATE OR REPLACE FUNCTION usr_get_last_password_date
(
	vr_user_id 	UUID
)
RETURNS TIMESTAMP
AS
$$
BEGIN
	RETURN (
		SELECT h.set_date
		FROM usr_passwords_history AS h
		WHERE h.user_id = vr_user_id
		ORDER BY h.id DESC
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

