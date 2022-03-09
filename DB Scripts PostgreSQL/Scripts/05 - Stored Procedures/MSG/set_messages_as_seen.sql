DROP FUNCTION IF EXISTS msg_set_messages_as_seen;

CREATE OR REPLACE FUNCTION msg_set_messages_as_seen
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN	
	IF vr_user_id IS NOT NULL AND vr_thread_id IS NOT NULL THEN
		UPDATE msg_message_details AS md
		SET seen = TRUE,
			view_date = COALESCE(md.view_date, vr_now)::TIMESTAMP
		WHERE md.application_id = vr_application_id AND
			md.user_id = vr_user_id AND md.thread_id = vr_thread_id AND md.view_date IS NULL;
		
		RETURN 1::INTEGER;
	ELSE 
		RETURN 0::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;




