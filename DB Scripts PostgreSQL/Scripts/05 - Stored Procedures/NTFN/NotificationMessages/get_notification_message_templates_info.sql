DROP FUNCTION IF EXISTS ntfn_get_notification_message_templates_info;

CREATE OR REPLACE FUNCTION ntfn_get_notification_message_templates_info
(
	vr_application_id	UUID
)
RETURNS TABLE (
	template_id		UUID,
	subject_type	VARCHAR,
	"action"		VARCHAR,
	media			VARCHAR,
	user_status		VARCHAR,
	lang			VARCHAR,
	subject			VARCHAR,
	text			VARCHAR,
	"enable"		BOOLEAN	
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	template_id,
			subject_type,
			"action",
			media,
			user_status,
			lang,
			subject,
			text,
			"enable"
	FROM ntfn_notification_message_templates AS n
	WHERE n.application_id = vr_application_id;
END;
$$ LANGUAGE plpgsql;

