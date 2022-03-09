DROP FUNCTION IF EXISTS msg_get_message_receivers;

CREATE OR REPLACE FUNCTION msg_get_message_receivers
(
	vr_application_id	UUID,
	vr_message_ids 		guid_table_type[],
	vr_count		 	INTEGER,
	vr_last_id		 	INTEGER
)
RETURNS TABLE (
	message_id		UUID, 
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
	WITH "data" AS
	(
		SELECT  (ROW_NUMBER() OVER (PARTITION BY md.message_id 
									ORDER BY md.id DESC))::BIGINT AS "row_number", 
				md.message_id, 
				md.user_id
		FROM UNNEST(vr_message_ids) AS r
			INNER JOIN msg_message_details AS md
			ON md.message_id = r.value
		WHERE md.application_id = vr_application_id AND md.is_sender = FALSE
	),
	total AS 
	(
		SELECT COUNT(*)::BIGINT AS total_count
		FROM "data" AS d
	),
	new_data AS
	(
		SELECT 	d.row_number,
				d.message_id,
				d.user_id
		FROM "data" AS d
			CROSS JOIN total AS "t"
		WHERE d.row_number > COALESCE(vr_last_id, 0) AND 
			d.row_number <= (COALESCE(vr_last_id, 0) + COALESCE(vr_count, 3))
	)
	SELECT	d.message_id, 
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





