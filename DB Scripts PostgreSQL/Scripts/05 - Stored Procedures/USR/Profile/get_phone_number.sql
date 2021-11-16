DROP FUNCTION IF EXISTS usr_get_phone_number;

CREATE OR REPLACE FUNCTION usr_get_phone_number
(
    vr_number_id	UUID
)
RETURNS TABLE (
	user_id			UUID,
	number_id		UUID, 
	phone_number	VARCHAR, 
	phone_type		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	pn.user_id,
			pn.number_id, 
			pn.phone_number, 
			pn.phone_type
	FROM usr_phone_numbers AS pn
	WHERE pn.number_id = vr_number_id;
END;
$$ LANGUAGE plpgsql;

