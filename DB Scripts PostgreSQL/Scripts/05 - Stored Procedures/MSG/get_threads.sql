DROP FUNCTION IF EXISTS msg_get_threads;

CREATE OR REPLACE FUNCTION msg_get_threads
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_count		 	INTEGER,
    vr_last_id		 	INTEGER
)
RETURNS TABLE (
	thread_id		UUID, 
	username		VARCHAR,
	first_name		VARCHAR,
	last_name		VARCHAR,
	is_group		BOOLEAN,
	messages_count	INTEGER,
	sent_count		INTEGER,
	not_seen_count	INTEGER,
	"row_number"	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	d.thread_id, 
			un.username, 
			un.first_name, 
			un.last_name,
			CASE WHEN un.user_id IS NULL THEN TRUE ELSE FALSE END::BOOLEAN AS is_group,
			d.messages_count,
			d.sent_count,
			d.not_seen_count,
			d.row_number
	FROM (
			SELECT 	(ROW_NUMBER() OVER (ORDER BY MAX(md.id) DESC))::INTEGER AS "row_number",
					md.thread_id, 
					MAX(md.id) AS max_id,
					COUNT(md.id)::INTEGER AS messages_count, 
					SUM(md.is_sender::INTEGER)::INTEGER AS sent_count,
					SUM(CASE 
						WHEN md.is_sender = FALSE AND md.seen = FALSE THEN 1 
						ELSE 0 
					END::INTEGER)::INTEGER AS not_seen_count
			FROM msg_message_details AS md
			WHERE md.application_id = vr_application_id AND 
				md.user_id = vr_user_id AND md.deleted = FALSE
			GROUP BY md.thread_id
		) AS d
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.thread_id
	WHERE (vr_last_id IS NULL OR d.row_number > vr_last_id)
	ORDER BY d.row_number ASC
	LIMIT COALESCE(vr_count, 10);
END;
$$ LANGUAGE plpgsql;



