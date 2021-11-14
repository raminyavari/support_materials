DROP FUNCTION IF EXISTS usr_get_application_users_partitioned;

CREATE OR REPLACE FUNCTION usr_get_application_users_partitioned
(
	vr_application_ids	guid_table_type[],
    vr_count		 	INTEGER
)
RETURNS TABLE (
	application_id	UUID,
	user_id			UUID,
	username		VARCHAR,
	first_name		VARCHAR,
	last_name		VARCHAR,
	total_count		INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS (
		SELECT	ROW_NUMBER() OVER(PARTITION BY x.application_id ORDER BY x.random_id ASC) AS seq,
				x.*
		FROM (
				SELECT	app.application_id,
						usr.user_id,
						usr.username,
						usr.first_name,
						usr.last_name,
						gen_random_uuid() AS random_id
				FROM UNNEST(vr_application_ids) AS ids
					INNER JOIN rv_applications AS app
					ON app.application_id = ids.value
					INNER JOIN usr_user_applications AS ua
					ON ua.application_id = app.application_id
					INNER JOIN usr_profile AS usr
					ON usr.user_id = ua.user_id AND usr.is_approved = TRUE
			) AS x
	),
	total AS (
		SELECT COUNT(d.user_id) AS total_count
		FROM "data" AS d
	)
	SELECT	d.application_id,
			d.user_id,
			d.username,
			d.first_name,
			d.last_name,
			"t".total_count::INTEGER
	FROM "data" AS d
		CROSS JOIN total AS "t"
	WHERE d.seq <= vr_count
	ORDER BY d.application_id ASC, d.seq ASC;
END;
$$ LANGUAGE plpgsql;

