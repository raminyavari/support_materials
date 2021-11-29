DROP FUNCTION IF EXISTS evt_get_related_users;

CREATE OR REPLACE FUNCTION evt_get_related_users
(
	vr_application_id	UUID,
    vr_event_id			UUID
)
RETURNS TABLE (
	user_id				UUID,
	event_id			UUID,
	status				VARCHAR,
	done				BOOLEAN,
	real_finish_date	TIMESTAMP,
	username			VARCHAR,
	first_name			VARCHAR,
	last_name			VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT ru.user_id,
		   ru.event_id,
		   ru.status,
		   ru.done,
		   ru.real_finish_date,
		   un.username,
		   un.first_name,
		   un.last_name
	FROM evt_related_users AS ru
		INNER JOIN users_normal AS un 
		ON un.application_id = vr_application_id AND un.user_id = ru.user_id
	WHERE ru.application_id = vr_application_id AND
		ru.event_id = vr_event_id AND ru.deleted = FALSE AND un.is_approved = TRUE;
END;
$$ LANGUAGE plpgsql;

