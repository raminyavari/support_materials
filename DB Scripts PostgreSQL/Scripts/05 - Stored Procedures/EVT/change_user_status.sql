DROP FUNCTION IF EXISTS evt_change_user_status;

CREATE OR REPLACE FUNCTION evt_change_user_status
(
	vr_application_id	UUID,
    vr_event_id			UUID,
	vr_user_id			UUID,
	vr_new_status		VARCHAR(20)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE evt_related_users AS e
	SET status = vr_new_status
	WHERE e.application_id = vr_application_id AND 
		e.event_id = vr_event_id AND e.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

