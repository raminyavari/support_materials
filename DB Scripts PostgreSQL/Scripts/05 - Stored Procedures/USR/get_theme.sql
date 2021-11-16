DROP FUNCTION IF EXISTS usr_get_theme;

CREATE OR REPLACE FUNCTION usr_get_theme
(
	vr_user_id	UUID
)
RETURNS VARCHAR
AS
$$
BEGIN
	RETURN (
		SELECT pr.theme
		FROM usr_profile AS pr
		WHERE pr.user_id = vr_user_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

