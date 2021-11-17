DROP FUNCTION IF EXISTS usr_get_users_main_email;

CREATE OR REPLACE FUNCTION usr_get_users_main_email
(
	vr_user_ids	guid_table_type[]
)
RETURNS TABLE (
	email_id		UUID, 
	user_id			UUID, 
	email_address	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	ea.email_id, 
			un.user_id, 
			ea.email_address
	FROM UNNEST(vr_user_ids) AS ids
		INNER JOIN usr_profile AS un
		ON un.user_id = ids.value
		INNER JOIN usr_email_addresses AS ea
		ON ea.email_id = un.main_email_id
	WHERE ea.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

