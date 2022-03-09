DROP FUNCTION IF EXISTS ntfn_set_notification_message_template_text;

CREATE OR REPLACE FUNCTION ntfn_set_notification_message_template_text
(
	vr_application_id	UUID,
	vr_template_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP,
	vr_subject			VARCHAR(512),
	vr_text				VARCHAR
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE ntfn_notification_message_templates AS n
	SET subject = vr_subject,
		text = vr_text,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE n.application_id = vr_application_id AND n.template_id = vr_template_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

