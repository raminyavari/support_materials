DROP FUNCTION IF EXISTS usr_get_email_owners;

CREATE OR REPLACE FUNCTION usr_get_email_owners
(
	vr_emails	string_table_type[]
)
RETURNS TABLE (
	user_id			UUID,
	email_id		UUID, 
	email_address	VARCHAR,
	is_main			BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	ea.user_id, 
			ea.email_id, 
			ea.email_address,
			CASE WHEN usr.user_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN AS is_main
	FROM UNNEST(vr_emails) AS e
		INNER JOIN usr_email_addresses AS ea
		ON ea.email_address = e.value
		LEFT JOIN usr_profile AS usr
		ON usr.user_id = ea.user_id AND usr.main_email_id = ea.email_id
	WHERE ea.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

