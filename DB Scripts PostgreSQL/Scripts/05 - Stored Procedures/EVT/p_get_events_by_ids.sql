DROP FUNCTION IF EXISTS evt_p_get_events_by_ids;

CREATE OR REPLACE FUNCTION evt_p_get_events_by_ids
(
	vr_application_id	UUID,
    vr_event_ids 		UUID[],
	vr_full		 		BOOLEAN,
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF evt_event_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT e.event_id,
		   e.event_type,
		   e.title,
		   e.description,
		   e.begin_date,
		   e.finish_date,
		   e.creator_user_id,
		   vr_total_count
	FROM UNNEST(vr_event_ids) AS x
		INNER JOIN evt_events AS e
		ON e.application_id = vr_application_id AND e.event_id = x;
END;
$$ LANGUAGE plpgsql;

