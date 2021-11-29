DROP FUNCTION IF EXISTS evt_arithmetic_delete_event;

CREATE OR REPLACE FUNCTION evt_arithmetic_delete_event
(
	vr_application_id	UUID,
    vr_event_id 		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE evt_events AS e
	SET deleted = TRUE
	WHERE e.application_id = vr_application_id AND e.event_id = vr_event_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

