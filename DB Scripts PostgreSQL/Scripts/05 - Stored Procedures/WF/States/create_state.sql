DROP FUNCTION IF EXISTS wf_create_state;

CREATE OR REPLACE FUNCTION wf_create_state
(
	vr_application_id	UUID,
    vr_state_id			UUID,
	vr_title			VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER DEFAULT 0;
BEGIN
	vr_title := gfn_verify_string(vr_title);
	
	INSERT INTO wf_states (
		application_id,
		state_id,
		title,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_state_id,
		vr_title,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

