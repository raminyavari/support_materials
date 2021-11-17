DROP FUNCTION IF EXISTS usr_get_users_main_phone;

CREATE OR REPLACE FUNCTION usr_get_users_main_phone
(
	vr_user_ids	guid_table_type[]
)
RETURNS TABLE (
	number_id		UUID, 
	user_id			UUID, 
	phone_number	VARCHAR,
	phone_type		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	pn.number_id, 
			un.user_id, 
			pn.phone_number, 
			pn.phone_type
	FROM UNNEST(vr_user_ids) AS ids
		INNER JOIN usr_profile AS un
		ON un.user_id = ids.value
		INNER JOIN usr_phone_numbers AS pn
		ON pn.number_id = un.main_phone_id
	WHERE pn.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

