DROP FUNCTION IF EXISTS msg_get_thread_info;

CREATE OR REPLACE FUNCTION msg_get_thread_info
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_thread_id		UUID
)
RETURNS TABLE (
	messages_count	INTEGER, 
	sent_count		INTEGER,
	not_seen_count	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	COUNT(md.id)::INTEGER AS messages_count, 
			SUM(md.is_sender::INTEGER) AS sent_count,
			SUM(
				CASE WHEN md.is_sender = FALSE AND md.seen = FALSE THEN 1 ELSE 0 END::INTEGER
			)::INTEGER AS not_seen_count
	FROM msg_message_details AS md
	WHERE md.application_id = vr_application_id AND 
		md.user_id = vr_user_id AND md.thread_id = vr_thread_id AND md.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;



