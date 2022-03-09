DROP FUNCTION IF EXISTS ntfn_get_user_notifications_count;

CREATE OR REPLACE FUNCTION ntfn_get_user_notifications_count
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_seen		 		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN (
		SELECT COUNT(n.id)
		FROM ntfn_notifications AS n
		WHERE n.application_id = vr_application_id AND n.user_id = vr_user_id AND 
			(vr_seen IS NULL OR n.seen = vr_seen) AND n.deleted = FALSE
	);
END;
$$ LANGUAGE plpgsql;

