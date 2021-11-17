DROP FUNCTION IF EXISTS usr_get_phone_owners;

CREATE OR REPLACE FUNCTION usr_get_phone_owners
(
	vr_numbers	string_table_type[]
)
RETURNS TABLE (
	user_id			UUID,
	number_id		UUID, 
	phone_number	VARCHAR,
	is_main			BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	pn.user_id, 
			pn.number_id, 
			pn.phone_number,
			CASE WHEN usr.user_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN AS is_main
	FROM UNNEST(vr_numbers) AS n
		INNER JOIN usr_phone_numbers AS pn
		ON pn.phone_number = n.value
		LEFT JOIN usr_profile AS usr
		ON usr.user_id = pn.user_id AND usr.main_phone_id = pn.number_id
	WHERE pn.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

