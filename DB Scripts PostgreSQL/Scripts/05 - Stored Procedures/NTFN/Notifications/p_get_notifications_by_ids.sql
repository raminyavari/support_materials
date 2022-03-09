DROP FUNCTION IF EXISTS ntfn_p_get_notifications_by_ids;

CREATE OR REPLACE FUNCTION ntfn_p_get_notifications_by_ids
(
	vr_application_id	UUID,
    vr_ids				BIGINT[],
	vr_total_count		BIGINT DEFAULT 0
)
RETURNS SETOF ntfn_notification_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT ntfn.id AS notification_id,
		   ntfn.user_id AS user_id,
		   ntfn.subject_id AS subject_id,
		   ntfn.ref_item_id AS ref_item_id,
		   ntfn.subject_name AS subject_name,
		   ntfn.subject_type AS subject_type,
		   ntfn.sender_user_id AS sender_user_id,
		   un.username AS sender_username,
		   un.first_name AS sender_first_name,
		   un.last_name AS sender_last_name,
		   ntfn.send_date AS send_date,
		   ntfn.action AS action,
		   ntfn.description AS description,
		   ntfn.info AS info,
		   ntfn.user_status AS user_status,
		   ntfn.seen AS seen,
		   ntfn.view_date AS view_date,
		   vr_total_count
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN ntfn_notifications AS ntfn
		ON ntfn.application_id = vr_application_id AND ntfn.id = rf
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ntfn.user_id
	ORDER BY ntfn.seen ASC, ntfn.id DESC;
END;
$$ LANGUAGE plpgsql;

