DROP FUNCTION IF EXISTS ntfn_get_user_notifications;

CREATE OR REPLACE FUNCTION ntfn_get_user_notifications
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_seen		 		BOOLEAN,
    vr_last_not_seen_id	BIGINT,
    vr_last_seen_id		BIGINT,
    vr_last_view_date 	TIMESTAMP,
    vr_lower_date_limit TIMESTAMP,
    vr_upper_date_limit TIMESTAMP,
    vr_count		 	INTEGER
)
RETURNS SETOF ntfn_notification_ret_composite
AS
$$
DECLARE
	vr_ids	BIGINT[];
BEGIN
	vr_ids := ARRAY(
		SELECT n.id
		FROM ntfn_notifications AS n
		WHERE n.application_id = vr_application_id AND n.user_id = vr_user_id AND
			(vr_lower_date_limit IS NULL OR n.send_date > vr_lower_date_limit) AND
			(vr_upper_date_limit IS NULL OR n.send_date < vr_upper_date_limit) AND
			(
				(
					(n.view_date IS NULL OR vr_last_view_date IS NULL) AND 
					(vr_last_not_seen_id IS NULL OR n.id < vr_last_not_seen_id)
				) OR
				(
					(n.view_date < vr_last_view_date) AND 
					(vr_last_seen_id IS NULL OR n.id < vr_last_seen_id)
				)
			) AND
			(vr_seen IS NULL OR n.seen = vr_seen) AND n.deleted = FALSE
		ORDER BY n.seen ASC, n.id DESC
		LIMIT COALESCE(vr_count, 20)
	);
	
	RETURN QUERY
	SELECT *
	FROM ntfn_p_get_notifications_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

