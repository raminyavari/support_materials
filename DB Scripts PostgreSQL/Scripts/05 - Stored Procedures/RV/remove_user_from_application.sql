DROP FUNCTION IF EXISTS rv_remove_user_from_application;

CREATE OR REPLACE FUNCTION rv_remove_user_from_application
(
	vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	DELETE FROM usr_user_applications AS ua
	WHERE ua.application_id = vr_application_id AND ua.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

