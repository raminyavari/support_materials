DROP FUNCTION IF EXISTS ntfn_arithmetic_delete_notification;

CREATE OR REPLACE FUNCTION ntfn_arithmetic_delete_notification
(
	vr_application_id	UUID,
	vr_id				BIGINT,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE ntfn_notifications AS n
	SET deleted = TRUE
	WHERE n.application_id = vr_application_id AND 
		n.id = vr_id AND n.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

