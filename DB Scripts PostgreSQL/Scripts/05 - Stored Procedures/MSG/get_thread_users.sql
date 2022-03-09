DROP FUNCTION IF EXISTS msg_get_thread_users;

CREATE OR REPLACE FUNCTION msg_get_thread_users
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_thread_ids		guid_table_type[],
	vr_count		 	INTEGER,
	vr_last_id		 	INTEGER
)
RETURNS TABLE (
	thread_id		UUID,
	user_id			UUID, 
	username		VARCHAR, 
	first_name		VARCHAR,
	last_name		VARCHAR,
	rev_row_number	INTEGER
)
AS
$$
BEGIN	
	RETURN QUERY
	WITH ref_data AS (
		SELECT 	md.thread_id, 
				MIN(md.id) AS min_id
		FROM UNNEST(vr_thread_ids) AS "t"
			INNER JOIN msg_message_details AS md
			ON md.application_id = vr_application_id AND md.thread_id = "t".value
		GROUP BY md.thread_id
	),
	msg_ids AS
	(
		SELECT 	md.thread_id, 
				md.message_id
		FROM ref_data AS x
			INNER JOIN msg_message_details AS md
			ON md.application_id = vr_application_id AND md.id = x.min_id
	),
	"data" AS 
	(
		SELECT  (ROW_NUMBER() OVER (PARTITION BY md.thread_id ORDER BY md.id DESC))::BIGINT AS "row_number", 
				md.thread_id, 
				md.user_id
		FROM msg_ids AS "m"
			INNER JOIN msg_message_details AS md
			ON md.thread_id = "m".thread_id AND md.message_id = "m".message_id
		WHERE md.application_id = vr_application_id AND md.user_id <> vr_user_id
	),
	total AS
	(
		SELECT COUNT(*)::BIGINT AS total_count
		FROM "data" AS d
	),
	new_data AS
	(
		SELECT 	d.thread_id,
				d.user_id,
				d.row_number,
				"t".total_count
		FROM "data" AS d
			CROSS JOIN total AS "t"
		WHERE d.row_number > COALESCE(vr_last_id, 0) AND 
			d.row_number <= (COALESCE(vr_last_id, 0) + COALESCE(vr_count, 3))
	)
	SELECT	d.thread_id, 
			d.user_id, 
			un.username, 
			un.first_name, 
			un.last_name,
			(d.total_count - d.row_number + 1)::INTEGER AS rev_row_number
	FROM new_data AS d
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id;
END;
$$ LANGUAGE plpgsql;




