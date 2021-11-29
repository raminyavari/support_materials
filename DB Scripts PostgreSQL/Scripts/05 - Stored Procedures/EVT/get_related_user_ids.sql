DROP FUNCTION IF EXISTS evt_get_related_user_ids;

CREATE OR REPLACE FUNCTION evt_get_related_user_ids
(
	vr_application_id	UUID,
    vr_event_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT ru.user_id
	FROM evt_related_users AS ru
	WHERE ru.application_id = vr_application_id AND 
		ru.event_id = vr_event_id AND ru.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

