DROP FUNCTION IF EXISTS wf_arithmetic_delete_state;

CREATE OR REPLACE FUNCTION wf_arithmetic_delete_state
(
	vr_application_id	UUID,
    vr_state_id			UUID,
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER DEFAULT 0;
BEGIN
	UPDATE wf_states AS s
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

