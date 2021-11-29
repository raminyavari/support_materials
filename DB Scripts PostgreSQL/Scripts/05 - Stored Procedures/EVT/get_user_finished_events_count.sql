DROP FUNCTION IF EXISTS evt_get_user_finished_events_count;

CREATE OR REPLACE FUNCTION evt_get_user_finished_events_count
(
	vr_application_id	UUID,
    vr_user_id			UUID,
	vr_current_date 	TIMESTAMP,
	vr_done		 		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(ev.event_id)
		FROM evt_related_users AS ru
			INNER JOIN evt_events AS ev
			ON ev.application_id = vr_application_id AND ev.event_id = ru.event_id
		WHERE ru.application_id = vr_application_id AND 
			ru.user_id = vr_user_id AND ev.finish_date <= vr_current_date AND
			(vr_done IS NULL OR ru.done = vr_done) AND ev.deleted = FALSE AND ru.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

