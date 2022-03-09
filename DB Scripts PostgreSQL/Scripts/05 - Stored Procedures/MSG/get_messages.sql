DROP FUNCTION IF EXISTS msg_get_messages;

CREATE OR REPLACE FUNCTION msg_get_messages
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_sent		 		BOOLEAN,
    vr_count		 	INTEGER,
    vr_min_id			BIGINT
)
RETURNS TABLE (
	message_id		UUID,
	title			VARCHAR,
	"message_text"	VARCHAR,
	send_date		TIMESTAMP,
	sender_user_id	UUID,
	forwarded_from	UUID,
	"id"			BIGINT,
	is_group		BOOLEAN,
	is_sender		BOOLEAN,
	seen			BOOLEAN,
	thread_id		UUID,
	username		VARCHAR,
	first_name		VARCHAR,
	last_name		VARCHAR,
	has_attachment	BOOLEAN	
)
AS
$$
BEGIN
	-- vr_sent IS NULL --> Sent and Received Messages
	-- vr_sent IS NOT NULL --> vr_sent = 1 --> Sent Messages
	--                     --> vr_sent = 0 --> Received Messages

	RETURN QUERY
	SELECT 	"m".message_id,
			"m".title,
			"m".message_text,
			"m".send_date,
			"m".sender_user_id,
			"m".forwarded_from,
			d.id,
			d.is_group,
			d.is_sender,
			d.seen,
			d.thread_id,
			un.username,
			un.first_name,
			un.last_name,
			"m".has_attachment
	FROM (
			SELECT *
			FROM msg_message_details AS md
			WHERE md.application_id = vr_application_id AND
				(vr_min_id IS NULL OR  md.id < vr_min_id) AND 
				md.user_id = vr_user_id AND
				(md.thread_id IS NULL OR md.thread_id = vr_thread_id) AND 
				(vr_sent IS NULL OR md.is_sender = vr_sent) AND 
				md.deleted = FALSE
			ORDER BY md.id DESC
			LIMIT COALESCE(vr_count, 20)
		) AS d
		INNER JOIN msg_messages AS "m"
		ON "m".application_id = vr_application_id AND "m".message_id = d.message_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = "m".sender_user_id
	ORDER BY d.id ASC;
END;
$$ LANGUAGE plpgsql;



