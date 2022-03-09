DROP FUNCTION IF EXISTS lg_get_logs;

CREATE OR REPLACE FUNCTION lg_get_logs
(
	vr_application_id	UUID,
	vr_user_ids			guid_table_type[],
    vr_actions			string_table_type[],
    vr_begin_date	 	TIMESTAMP,
    vr_finish_date	 	TIMESTAMP,
    vr_last_id			BIGINT,
    vr_count		 	INTEGER
)
RETURNS SETOF lg_log_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM lg_p_get_logs(
		vr_application_id, 
		ARRAY(
			SELECT x.value
			FROM UNNEST(vr_user_ids) AS x
		), 
		ARRAY(
			SELECT x.value::VARCHAR
			FROM UNNEST(vr_actions) AS x
		),
		vr_begin_date, 
		vr_finish_date, 
		vr_last_id, 
		vr_count
	);
END;
$$ LANGUAGE plpgsql;

