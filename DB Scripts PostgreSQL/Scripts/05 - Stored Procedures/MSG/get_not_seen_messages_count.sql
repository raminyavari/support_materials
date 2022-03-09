DROP FUNCTION IF EXISTS msg_get_not_seen_messages_count;

CREATE OR REPLACE FUNCTION msg_get_not_seen_messages_count
(
	vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
BEGIN	
	RETURN COALESCE((
		SELECT COUNT(md.id)
		FROM msg_message_details AS md
		WHERE md.application_id = vr_application_id AND
			md.user_id = vr_user_id AND md.is_sender = FALSE AND 
			md.seen = FALSE AND md.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;




