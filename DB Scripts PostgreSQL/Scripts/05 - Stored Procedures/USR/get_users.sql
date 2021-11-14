DROP FUNCTION IF EXISTS usr_get_users;

CREATE OR REPLACE FUNCTION usr_get_users
(
	vr_application_id	UUID,
	vr_search_text  	VARCHAR(1000),
    vr_lower_boundary	BIGINT,
    vr_count		 	INTEGER,
    vr_is_online 		BOOLEAN,
    vr_is_approved	 	BOOLEAN,
    vr_now		 		TIMESTAMP
)
RETURNS SETOF usr_user_ret_composite
AS
$$
DECLARE
	vr_ret_ids				UUID[];
	vr_total_count			BIGINT;
	vr_online_time_treshold TIMESTAMP;
BEGIN
	vr_search_text := gfn_verify_string(COALESCE(vr_search_text, ''));
	vr_count := COALESCE(vr_count, 20)::INTEGER;
	vr_is_online := COALESCE(vr_is_online, FALSE)::BOOLEAN;
	vr_online_time_treshold := vr_now - INTERVAL '1 MINUTE';
	
	WITH vr_tbl AS (
		SELECT	ROW_NUMBER() OVER (ORDER BY pgroonga_score("p".tableoid, "p".ctid)::FLOAT DESC, "p".user_id DESC) AS seq,
				"p".user_id
		FROM usr_profile AS "p"
			INNER JOIN usr_user_applications AS app
			ON app.application_id = vr_application_id AND app.user_id = "p".user_id
		WHERE (vr_search_text = '' OR "p".username &@~ vr_search_text OR 
				"p".first_name &@~ vr_search_text OR "p".last_name &@~ vr_search_text
			) AND
			(vr_is_approved IS NULL OR COALESCE("p".is_approved, TRUE) = vr_is_approved) AND
			(vr_is_online = FALSE OR "p".last_activity_date >= vr_online_time_treshold)
	),
	total AS (
		SELECT COUNT("t".user_id) AS total_count
		FROM vr_tbl AS "t"
	)
	SELECT	vr_total_count = (
				SELECT "t".total_count::BIGINT
				FROM total AS "t"
				LIMIT 1
			),
			vr_ret_ids = ARRAY(
				SELECT "t".user_id
				FROM vr_tbl AS "t"
				WHERE "t".seq >= COALESCE(vr_lower_boundary, 0)
				ORDER BY "t".seq ASC
				LIMIT vr_count
			);
	
	RETURN QUERY
	SELECT *
	FROM usr_p_get_users_by_ids(vr_application_id, vr_ret_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;

