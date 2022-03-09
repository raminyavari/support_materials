DROP FUNCTION IF EXISTS ntfn_get_notification_messages_info;

CREATE OR REPLACE FUNCTION ntfn_get_notification_messages_info
(
	vr_application_id	UUID,
	vr_ref_app_id		UUID,
	vr_user_status_pair guid_string_table_type[],
    vr_subject_type		VARCHAR(50),
	vr_action			VARCHAR(50)
)
RETURNS TABLE (
	user_id	UUID, 
	media	VARCHAR,
	lang	VARCHAR,
	subject	VARCHAR,
	text	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	ust.first_value AS user_id, 
			mt.media,
			mt.lang,
			mt.subject,
			mt.text
	FROM UNNEST(vr_user_status_pair) AS ust
		INNER JOIN ntfn_user_messaging_activation AS so
		ON so.application_id = vr_application_id AND so.user_id = ust.first_value
		RIGHT JOIN ntfn_notification_message_templates AS mt
		ON mt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
			mt.user_status = ust.second_value AND 
			mt.action = so.action AND mt.subject_type = so.subject_type AND 
			mt.media = so.media AND mt.lang = so.lang
	WHERE mt.application_id = COALESCE(vr_ref_app_id, vr_application_id) AND 
		mt.action = vr_action AND mt.subject_type = vr_subjectType AND 
		mt.enable = TRUE AND COALESCE(so.enable, TRUE) = TRUE;
END;
$$ LANGUAGE plpgsql;

