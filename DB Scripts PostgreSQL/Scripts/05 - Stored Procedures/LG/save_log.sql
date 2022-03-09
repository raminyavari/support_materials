DROP FUNCTION IF EXISTS lg_save_log;

CREATE OR REPLACE FUNCTION lg_save_log
(
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_host_address			VARCHAR(100),
	vr_host_name		 	VARCHAR(255),
	vr_action				VARCHAR(100),
	vr_level				VARCHAR(20),
	vr_not_authorized	 	BOOLEAN,
	vr_subject_ids			guid_table_type[],
	vr_second_subject_id	UUID,
	vr_third_subject_id		UUID,
	vr_fourth_subject_id	UUID,
	vr_date			 		TIMESTAMP,
	vr_info			 		VARCHAR,
	vr_module_identifier	VARCHAR(20)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO lg_logs (
		application_id,
		user_id,
		host_address,
		host_name,
		"action",
		"level",
		not_authorized,
		subject_id,
		second_subject_id,
		third_subject_id,
		fourth_subject_id,
		date,
		"info",
		module_identifier
	)
	SELECT 	vr_application_id, 
			vr_user_id, 
			vr_host_address, 
			vr_host_name, 
			vr_action, 
			vr_level, 
			vr_not_authorized, 
			rf.value, 
			vr_second_subject_id, 
			vr_third_subject_id, 
			vr_fourth_subject_id, 
			vr_date, 
			vr_info, 
			vr_module_identifier
	FROM UNNEST(vr_subject_ids) AS rf;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

