DROP FUNCTION IF EXISTS ntfn_arithmetic_delete_notifications;

CREATE OR REPLACE FUNCTION ntfn_arithmetic_delete_notifications
(
	vr_application_id	UUID,
    vr_subject_ids		guid_table_type[],
    vr_ref_item_ids		guid_table_type[],
    vr_sender_user_id	UUID,
    vr_actions			string_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_actions_count 		INTEGER;
	vr_subject_ids_count	INTEGER;
	vr_ref_item_ids_count 	INTEGER;
	vr_result				INTEGER;
BEGIN
	vr_actions_count := COALESCE(ARRAY_LENGTH(vr_actions, 1), 0);
	vr_subject_ids_count := COALESCE(ARRAY_LENGTH(vr_subject_ids, 1), 0);
	vr_ref_item_ids_count := COALESCE(ARRAY_LENGTH(vr_ref_item_ids, 1), 0);
	
	IF vr_subject_ids_count > 0 AND vr_ref_item_ids_count > 0 THEN	
		UPDATE ntfn_notifications
		SET deleted = TRUE
		FROM UNNEST(vr_subject_ids) AS s
			INNER JOIN ntfn_notifications AS n
			ON n.subject_id = s.value
			INNER JOIN UNNEST(vr_ref_item_ids) AS r
			ON r.value = n.ref_item_id
		WHERE n.application_id = vr_application_id AND
			(vr_sender_user_id IS NULL OR n.sender_user_id = vr_sender_user_id) AND
			(vr_actions_count = 0 OR n.action IN(SELECT * FROM vr_actions));
	ELSEIF vr_subject_ids_count > 0 THEN
		UPDATE ntfn_notifications
		SET deleted = TRUE
		FROM UNNEST(vr_subject_ids) AS s
			INNER JOIN ntfn_notifications AS n
			ON n.subject_id = s.value
		WHERE n.application_id = vr_application_id AND 
			(vr_sender_user_id IS NULL OR n.sender_user_id = vr_sender_user_id) AND
			(vr_actions_count = 0 OR n.action IN (SELECT x.value FROM UNNEST(vr_actions) AS x));
	ELSEIF vr_ref_item_ids_count > 0 THEN
		UPDATE ntfn_notifications
		SET deleted = TRUE
		FROM UNNEST(vr_ref_item_ids) AS r
			INNER JOIN ntfn_notifications AS n
			ON n.ref_item_id = r.value
		WHERE n.application_id = vr_application_id AND 
			(vr_sender_user_id IS NULL OR n.sender_user_id = vr_sender_user_id) AND
			(vr_actions_count = 0 OR n.action IN (SELECT x.value FROM UNNEST(vr_actions) AS x));
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

