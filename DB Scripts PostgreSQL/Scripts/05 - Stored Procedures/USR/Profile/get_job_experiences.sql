DROP FUNCTION IF EXISTS usr_get_job_experiences;

CREATE OR REPLACE FUNCTION usr_get_job_experiences
(
	vr_application_id 	UUID,
    vr_user_id			UUID
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
	WHERE je.application_id = vr_application_id AND je.user_id = vr_user_id AND deleted = FALSE
	ORDER BY je.start_date DESC;
END;
$$ LANGUAGE plpgsql;

