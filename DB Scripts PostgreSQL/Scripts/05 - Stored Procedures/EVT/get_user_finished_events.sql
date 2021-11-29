DROP FUNCTION IF EXISTS evt_get_user_finished_events;

CREATE OR REPLACE FUNCTION evt_get_user_finished_events
(
	vr_application_id	UUID,
    vr_user_id			UUID,
	vr_now 				TIMESTAMP,
	vr_done		 		BOOLEAN
)
RETURNS SETOF evt_event_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT e.event_id
		FROM evt_related_users AS ru
			INNER JOIN evt_events AS e
			ON e.application_id = vr_application_id AND ru.event_id = e.event_id
		WHERE ru.application_id = vr_application_id AND 
			ru.user_id = vr_user_id AND e.finish_date <= vr_current_date AND
			(vr_done IS NULL OR ru.done = vr_done) AND e.deleted = FALSE AND ru.deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM evt_p_get_events_by_ids(vr_application_id, vr_ids, vr_full);
END;
$$ LANGUAGE plpgsql;

