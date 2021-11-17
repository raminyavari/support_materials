DROP FUNCTION IF EXISTS usr_remove_language;

CREATE OR REPLACE FUNCTION usr_remove_language
(
	vr_application_id	UUID,
	vr_id				UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result		INTEGER;
BEGIN
	UPDATE usr_user_languages AS l
	SET deleted = TRUE
	WHERE l.application_id = vr_application_id AND l.id = vr_id AND l.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

