DROP FUNCTION IF EXISTS usr_set_employment_type;

CREATE OR REPLACE FUNCTION usr_set_employment_type
(
	vr_application_id	UUID,
    vr_user_id 			UUID,
    vr_employment_type 		VARCHAR(50)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_user_applications AS ap
	SET employment_type = gfn_verify_string(vr_employment_type)
	WHERE ap.application_id = vr_application_id AND ap.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

