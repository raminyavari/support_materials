DROP FUNCTION IF EXISTS fg_remove_poll;

CREATE OR REPLACE FUNCTION fg_remove_poll
(
	vr_application_id		UUID,
	vr_poll_id				UUID,
	vr_current_user_id		UUID,
	vr_now		 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_polls AS "p"
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE "p".application_id = vr_application_id AND "p".poll_id = vr_poll_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

