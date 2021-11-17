DROP FUNCTION IF EXISTS usr_get_job_experience;

CREATE OR REPLACE FUNCTION usr_get_job_experience
(
	vr_application_id 	UUID,
    vr_job_id			UUID
)
RETURNS TABLE (
	job_id		UUID, 
	user_id		UUID,
	title		VARCHAR, 
	employer	VARCHAR,
	start_date	TIMESTAMP,
	end_date	TIMESTAMP
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	je.job_id, 
			je.user_id,
			je.title, 
			je.employer,
			je.start_date,
			je.end_date
	FROM usr_job_experiences AS je
	WHERE je.application_id = vr_application_id AND je.job_id = vr_job_id;
END;
$$ LANGUAGE plpgsql;

