DROP FUNCTION IF EXISTS lg_save_error_log;

CREATE OR REPLACE FUNCTION lg_save_error_log
(
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_subject				VARCHAR(1000),
	vr_description	 		VARCHAR(2000),
	vr_date			 		TIMESTAMP,
	vr_module_identifier	VARCHAR(20),
	vr_level				VARCHAR(20)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO lg_error_logs (
		application_id,
		user_id,
		subject,
		description,
		date,
		module_identifier,
		"level"
	)
	VALUES (
		vr_application_id,
		vr_user_id, 
		vr_subject, 
		vr_description, 
		vr_date, 
		vr_module_identifier,
		vr_level
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

