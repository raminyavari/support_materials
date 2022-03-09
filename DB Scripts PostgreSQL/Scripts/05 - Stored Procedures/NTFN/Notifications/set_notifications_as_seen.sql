DROP FUNCTION IF EXISTS ntfn_set_notifications_as_seen;

CREATE OR REPLACE FUNCTION ntfn_set_notifications_as_seen
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_ids				big_int_table_type[],
    vr_view_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE ntfn_notifications
	SET seen = TRUE,
		view_date = vr_view_date
	FROM (
			SELECT DISTINCT x.value
			FROM UNNEST(vr_ids) AS x
		) AS rf
		INNER JOIN ntfn_notifications AS n
		ON n.id = rf.value
	WHERE n.application_id = vr_application_id AND n.user_id = vr_user_id AND n.seen = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

