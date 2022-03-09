DROP FUNCTION IF EXISTS msg_has_message;

CREATE OR REPLACE FUNCTION msg_has_message
(
	vr_application_id	UUID,
	vr_id				BIGINT,
    vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_message_id		UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM msg_message_details AS md
		WHERE md.application_id = vr_application_id AND 
			(vr_id IS NULL OR md.id = vr_id) AND
			md.user_id = vr_user_id AND 
			(vr_thread_id IS NULL OR md.thread_id = vr_thread_id) AND
			(vr_message_id IS NULL OR md.message_id = vr_message_id)
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;



