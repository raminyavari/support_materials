DROP FUNCTION IF EXISTS wf_arithmetic_delete_auto_message;

CREATE OR REPLACE FUNCTION wf_arithmetic_delete_auto_message
(
	vr_application_id	UUID,
	vr_auto_message_id	UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_auto_messages AS "m"
	SET	deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE "m".application_id = vr_application_id AND "m".auto_message_id = vr_auto_message_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

