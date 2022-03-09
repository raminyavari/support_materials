DROP FUNCTION IF EXISTS ntfn_get_user_messaging_activation;

CREATE OR REPLACE FUNCTION ntfn_get_user_messaging_activation
(
	vr_application_id	UUID,
	vr_ref_app_id		UUID,
	vr_user_id			UUID
)
RETURNS TABLE (
	option_id		UUID,
	subject_type	VARCHAR,
	user_id			UUID,
	user_status		VARCHAR,
	"action"		VARCHAR,
	media			VARCHAR,
	lang			VARCHAR,
	"enable"		BOOLEAN,
	admin_enable	BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	uma.option_id,
			CASE
				WHEN uma.subject_type IS NULL THEN nmt.subject_type
				ELSE uma.subject_type
			END AS subject_type,
			uma.user_id,
			CASE
				WHEN uma.user_status IS NULL THEN nmt.user_status
				ELSE uma.user_status
			END AS user_status,
			CASE
				WHEN uma.action IS NULL THEN nmt.action
				ELSE uma.action
			END AS action,
			CASE
				WHEN uma.media IS NULL THEN nmt.media
				ELSE uma.media
			END AS media,
			CASE
				WHEN uma.lang IS NULL THEN nmt.lang
				ELSE uma.lang
			END AS lang,
			uma.enable,
			nmt.enable AS admin_enable
	FROM ntfn_user_messaging_activation AS uma
		FULL OUTER JOIN ntfn_notification_message_templates AS nmt
		ON uma.application_id = vr_application_id AND 
			nmt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
			uma.user_id = vr_user_id AND nmt.action = uma.action AND 
			nmt.lang = uma.lang AND nmt.media = uma.media AND 
			nmt.subject_type = uma.subject_type AND nmt.user_status = uma.user_status
	WHERE uma.application_id = vr_application_id AND 
		nmt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
		uma.user_id IS NULL OR uma.user_id = vr_user_id;
END;
$$ LANGUAGE plpgsql;

