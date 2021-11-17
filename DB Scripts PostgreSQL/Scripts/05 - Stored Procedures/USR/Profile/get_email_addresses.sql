DROP FUNCTION IF EXISTS usr_get_email_addresses;

CREATE OR REPLACE FUNCTION usr_get_email_addresses
(
	vr_user_id	UUID
)
RETURNS TABLE (
	user_id			UUID,
	email_id		UUID, 
	email_address	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	e.user_id,
			e.email_id, 
			e.email_address
	FROM usr_email_addresses AS e
	WHERE e.user_id = vr_user_id AND e.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

