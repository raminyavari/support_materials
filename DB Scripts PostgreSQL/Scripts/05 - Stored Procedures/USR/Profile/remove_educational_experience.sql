DROP FUNCTION IF EXISTS usr_remove_educational_experience;

CREATE OR REPLACE FUNCTION usr_remove_educational_experience
(
	vr_application_id	UUID,
	vr_education_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result		INTEGER;
BEGIN
	UPDATE usr_educational_experiences AS ex
	SET deleted = TRUE
	WHERE ex.application_id = vr_application_id AND ex.education_id = vr_education_id AND ex.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

