DROP FUNCTION IF EXISTS ntfn_send_notification;

CREATE OR REPLACE FUNCTION ntfn_send_notification
(
	vr_application_id	UUID,
    vr_users			guid_string_table_type[],
    vr_subject_id 		UUID,
    vr_ref_item_id 		UUID,
    vr_subject_type		VARCHAR(20),
    vr_subject_name 	VARCHAR(2000),
    vr_action			VARCHAR(20),
    vr_sender_user_id 	UUID,
    vr_send_date	 	TIMESTAMP,
    vr_description 		VARCHAR(2000),
    vr_info		 		VARCHAR(2000)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_users := ARRAY(
		SELECT ROW(rf.first_value, rf.second_value)
		FROM UNNEST(vr_users) AS rf
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = rf.first_value	
	);

	INSERT INTO ntfn_notifications (
		application_id,
		user_id,
		subject_id,
		ref_item_id,
		subject_type,
		subject_name,
		"action",
		sender_user_id,
		send_date,
		description,
		"info",
		user_status,
		seen,
		deleted
	)
	SELECT 	vr_application_id, 
			rf.first_value, 
			vr_subject_id, 
			vr_ref_item_id, 
			vr_subject_type, 
			vr_subject_name, 
			vr_action, 
			vr_sender_user_id, 
			vr_send_date, 
			vr_description, 
			vr_info, 
			rf.second_value, 
			FALSE, 
			FALSE
	FROM UNNEST(vr_users) AS rf
	WHERE rf.first_value <> vr_sender_user_id AND NOT EXISTS (
			SELECT 1
			FROM ntfn_notifications AS x
			WHERE x.application_id = vr_application_id AND x.user_id = rf.first_value AND 
				x.subject_id = vr_subject_id AND x.ref_item_id = vr_ref_item_id AND 
				x.action = vr_action AND x.sender_user_id = vr_sender_user_id AND x.deleted = FALSE
			LIMIT 1
		);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

