DROP FUNCTION IF EXISTS usr_set_birthday;

CREATE OR REPLACE FUNCTION usr_set_birthday
(
	vr_application_id	UUID,
    vr_user_id 			UUID,
    vr_birthdate	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET birthdate = vr_birthdate
	WHERE pr.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

