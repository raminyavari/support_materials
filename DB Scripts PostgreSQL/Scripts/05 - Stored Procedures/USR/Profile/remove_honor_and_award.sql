DROP FUNCTION IF EXISTS usr_remove_honor_and_award;

CREATE OR REPLACE FUNCTION usr_remove_honor_and_award
(
	vr_application_id	UUID,
	vr_honor_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result		INTEGER;
BEGIN
	UPDATE usr_honors_and_awards AS ha
	SET deleted = TRUE
	WHERE ha.application_id = vr_application_id AND ha.id = vr_honor_id AND ha.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

