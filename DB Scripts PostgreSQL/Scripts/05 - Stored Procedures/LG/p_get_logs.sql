DROP FUNCTION IF EXISTS lg_p_get_logs;

CREATE OR REPLACE FUNCTION lg_p_get_logs
(
	vr_application_id	UUID,
	vr_user_ids			UUID[],
    vr_actions			VARCHAR[],
    vr_begin_date	 	TIMESTAMP,
    vr_finish_date	 	TIMESTAMP,
    vr_last_id			BIGINT,
    vr_count		 	INTEGER
)
RETURNS SETOF lg_log_ret_composite
AS
$$
DECLARE
	vr_actions_count	INTEGER;
	vr_users_count 		INTEGER;
BEGIN
	vr_actions_count := COALESCE(ARRAY_LENGTH(vr_actions, 1), 0)::INTEGER;
	vr_users_count := COALESCE(ARRAY_LENGTH(vr_user_ids, 1), 0)::INTEGER;
	vr_count := COALESCE(vr_count, 100)::INTEGER;
	
	IF vr_users_count = 0 THEN
		RETURN QUERY
		SELECT 	lg.log_id,
				lg.user_id,
				un.username,
				un.first_name,
				un.last_name,
				lg.host_address,
				lg.host_name,
				lg.action,
				lg.date,
				lg.info,
				lg.module_identifier
		FROM lg_logs AS lg
			LEFT JOIN usr_view_users AS un
			ON un.user_id = lg.user_id
		WHERE (vr_application_id IS NULL OR lg.application_id = vr_application_id) AND
			(vr_last_id IS NULL OR lg.log_id > vr_last_id) AND
			(vr_finish_date IS NULL OR lg.date < vr_finish_date) AND
			(vr_begin_date IS NULL OR lg.date > vr_begin_date) AND
			(vr_actions_count = 0 OR lg.action IN (SELECT UNNEST(vr_actions)))
		ORDER BY lg.log_id DESC
		LIMIT vr_count;
	ELSE 
		RETURN QUERY
		SELECT	lg.log_id,
				lg.user_id,
				un.username,
				un.first_name,
				un.last_name,
				lg.host_address,
				lg.host_name,
				lg.action,
				lg.date,
				lg.info,
				lg.module_identifier
		FROM UNNEST(vr_user_ids) AS usr
			INNER JOIN lg_logs AS lg
			ON (vr_application_id IS NULL OR lg.application_id = vr_application_id) AND
				lg.user_id = usr
			LEFT JOIN usr_view_users AS un
			ON un.user_id = lg.user_id
		WHERE (vr_last_id IS NULL OR lg.log_id > vr_last_id) AND
			(vr_finish_date IS NULL OR lg.date < vr_finish_date) AND
			(vr_begin_date IS NULL OR lg.date > vr_begin_date) AND
			(vr_actions_count = 0 OR lg.action IN (SELECT UNNEST(vr_actions)))
		ORDER BY lg.log_id DESC
		LIMIT vr_count;
	END IF;
END;
$$ LANGUAGE plpgsql;

