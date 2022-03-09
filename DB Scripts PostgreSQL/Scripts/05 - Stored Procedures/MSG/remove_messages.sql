DROP FUNCTION IF EXISTS msg_remove_messages;

CREATE OR REPLACE FUNCTION msg_remove_messages
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_id				BIGINT
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN	
	UPDATE msg_message_details AS d
	SET deleted = TRUE
	WHERE d.application_id = vr_application_id AND 
		(
			(vr_id IS NOT NULL AND d.id = vr_id) OR  
			(vr_id IS NULL AND d.user_id = vr_user_id AND d.thread_id = vr_thread_id)
		);
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;




