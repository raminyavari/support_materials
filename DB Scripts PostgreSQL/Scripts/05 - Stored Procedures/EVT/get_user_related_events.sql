DROP FUNCTION IF EXISTS evt_get_user_related_events;

CREATE OR REPLACE FUNCTION evt_get_user_related_events
(
	vr_application_id	UUID,
    vr_user_id			UUID,
	vr_current_date 	TIMESTAMP,
	vr_not_finished 	BOOLEAN,
	vr_status			VARCHAR(20),
	vr_node_id			UUID
)
RETURNS TABLE (
	event_id			UUID,
	user_id				UUID,
	event_type			VARCHAR,
	title				VARCHAR,
	description			VARCHAR,
	begin_date			TIMESTAMP,
	finish_date			TIMESTAMP,
	creator_user_id		UUID,
	status				VARCHAR,
	done				BOOLEAN,
	real_finish_date	TIMESTAMP
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	RETURN QUERY
	SELECT ev.event_id,
		   ru.user_id,
		   ev.event_type,
		   ev.title,
		   ev.description,
		   ev.begin_date,
		   ev.finish_date,
		   ev.creator_user_id,
		   ru.status,
		   ru.done,
		   ru.real_finish_date
	FROM evt_related_users AS ru 
		INNER JOIN evt_events AS ev 
		ON ev.application_id = vr_application_id AND ev.event_id = ru.event_id
	WHERE ru.application_id = vr_application_id AND ru.user_id = vr_user_id AND 
		(vr_current_date IS NULL OR ev.begin_date >= vr_current_date) AND
		(vr_not_finished IS NULL OR vr_not_finished = 0 OR ev.begin_date <= vr_current_date) AND
		(vr_status IS NULL OR ru.status = vr_status) AND
		ev.deleted = FALSE AND ru.deleted = FALSE AND
		(vr_node_id IS NULL OR EXISTS (
			SELECT 1
			FROM evt_related_nodes AS rn2
				INNER JOIN evt_events AS e2
				ON e2.event_id = rn2.event_id
			WHERE rn2.application_id = vr_application_id AND rn2.node_id = vr_node_id
			LIMIT 1
		));
END;
$$ LANGUAGE plpgsql;

