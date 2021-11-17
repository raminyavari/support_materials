DROP FUNCTION IF EXISTS usr_get_email_address;

CREATE OR REPLACE FUNCTION usr_get_email_address
(
	vr_email_id	UUID
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
	WHERE e.email_id = vr_email_id;
END;
$$ LANGUAGE plpgsql;

