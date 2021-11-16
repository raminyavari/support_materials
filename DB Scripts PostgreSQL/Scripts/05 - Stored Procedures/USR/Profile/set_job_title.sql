DROP FUNCTION IF EXISTS usr_set_job_title;

CREATE OR REPLACE FUNCTION usr_set_job_title
(
	vr_application_id	UUID,
    vr_user_id 			UUID,
    vr_job_title 		VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_user_applications AS ap
	SET job_title = gfn_verify_string(vr_job_title)
	WHERE ap.application_id = vr_application_id AND ap.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

