DROP FUNCTION IF EXISTS usr_set_city;

CREATE OR REPLACE FUNCTION usr_set_city
(
	vr_user_id 	UUID,
    vr_city 	VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET city = gfn_verify_string(vr_city)
	WHERE pr.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

