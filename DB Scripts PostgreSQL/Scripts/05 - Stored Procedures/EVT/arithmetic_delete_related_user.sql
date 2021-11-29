DROP FUNCTION IF EXISTS evt_arithmetic_delete_related_user;

CREATE OR REPLACE FUNCTION evt_arithmetic_delete_related_user
(
	vr_application_id	UUID,
    vr_event_id			UUID,
	vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_is_own 	BOOLEAN;
	vr_result	INTEGER;
BEGIN
	vr_is_own := COALESCE((
		SELECT TRUE
		FROM evt_events AS e
		WHERE e.application_id = vr_application_id AND 
			e.event_id = vr_event_id AND e.creator_user_id = vr_user_id
		LIMIT 1
	), FALSE)::BOOLEAN;
	
	UPDATE evt_related_users AS r
	SET deleted = TRUE
	WHERE r.application_id = vr_application_id AND 
		r.event_id = vr_event_id AND r.user_id = vr_user_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	IF vr_is_own = TRUE THEN
		UPDATE evt_events AS e
		SET deleted = TRUE
		WHERE e.application_id = vr_application_id AND e.event_id = vr_event_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;

		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::INTEGER;
		END IF;
		
		RETURN 2::INTEGER; /* 2: the event is deleted */
	ELSE 
		RETURN 1::INTEGER; /* 1: only the user has been deleted */
	END IF;
END;
$$ LANGUAGE plpgsql;

