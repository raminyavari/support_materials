DROP FUNCTION IF EXISTS rv_remove_application;

CREATE OR REPLACE FUNCTION rv_remove_application
(
	vr_application_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE rv_applications AS app
	SET deleted = TRUE
	WHERE app.application_id = vr_application_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

