DROP FUNCTION IF EXISTS usr_get_educational_experiences;

CREATE OR REPLACE FUNCTION usr_get_educational_experiences
(
	vr_application_id 	UUID,
    vr_user_id			UUID
)
RETURNS TABLE (
	education_id		UUID,
	user_id				UUID,
	school				VARCHAR,
	study_field			VARCHAR,
	"level"				VARCHAR,
	start_date			TIMESTAMP,
	end_date			TIMESTAMP,
	graduate_degree		VARCHAR,
	is_school			BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	ee.education_id,
			ee.user_id,
			ee.school,
			ee.study_field,
			ee.level,
			ee.start_date,
			ee.end_date,
			ee.graduate_degree,
			ee.is_school
	FROM usr_educational_experiences AS ee
	WHERE ee.application_id = vr_application_id AND ee.user_id = vr_user_id AND deleted = FALSE
	ORDER BY ee.start_date DESC;
END;
$$ LANGUAGE plpgsql;

