DROP FUNCTION IF EXISTS rv_add_user_to_application;

CREATE OR REPLACE FUNCTION rv_add_user_to_application
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	IF vr_application_id IS NOT NULL AND vr_user_id IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM usr_user_applications AS ua
		WHERE ua.application_id = vr_application_id AND ua.user_id = vr_user_id
		LIMIT 1
	) THEN
		INSERT INTO usr_user_applications (application_id, user_id, creation_date)
		VALUES (vr_application_id, vr_user_id, vr_now);
	END IF;
	
	RETURN CASE WHEN vr_application_id IS NULL OR vr_user_id IS NULL THEN 0 ELSE 1 END::INTEGER;
END;
$$ LANGUAGE plpgsql;

