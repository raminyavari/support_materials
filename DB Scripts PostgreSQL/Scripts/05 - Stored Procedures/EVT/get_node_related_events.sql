DROP FUNCTION IF EXISTS evt_get_node_related_events;

CREATE OR REPLACE FUNCTION evt_get_node_related_events
(
	vr_application_id	UUID,
    vr_node_id			UUID,
	vr_current_date 	TIMESTAMP,
	vr_not_finished 	BOOLEAN
)
RETURNS SETOF evt_event_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT e.event_id
		FROM evt_related_nodes AS rn
			INNER JOIN evt_events AS e
			ON e.application_id = vr_application_id AND e.event_id = rn.event_id
		WHERE rn.application_id = vr_application_id AND rn.node_id = vr_node_id AND 
			(vr_current_date IS NULL OR e.begin_date >= vr_current_date) AND
			(vr_not_finished IS NULL OR vr_not_finished = 0 OR e.begin_date <= vr_current_date) AND 
			e.deleted = FALSE AND rn.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM evt_p_get_events_by_ids(vr_application_id, vr_ids, FALSE);
END;
$$ LANGUAGE plpgsql;

