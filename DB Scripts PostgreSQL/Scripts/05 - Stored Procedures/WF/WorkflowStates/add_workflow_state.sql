DROP FUNCTION IF EXISTS wf_add_workflow_state;

CREATE OR REPLACE FUNCTION wf_add_workflow_state
(
	vr_application_id	UUID,
	vr_id				UUID,
    vr_workflow_id		UUID,
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
	IF EXISTS (
		SELECT 1
		FROM wf_workflow_states AS s
		WHERE s.application_id = vr_application_id AND 
			s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id
		LIMIT 1
	) THEN
		UPDATE wf_workflow_states AS s
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE s.application_id = vr_application_id AND 
			s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id AND s.deleted = TRUE;
	ELSE
		INSERT INTO wf_workflow_states (
			application_id,
			"id",
			workflow_id,
			state_id,
			response_type,
			"admin",
			description_needed,
			hide_owner_name,
			free_data_need_requests,
			edit_permission,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_iD,
			vr_workflow_id,
			vr_state_id,
			NULL,
			FALSE,
			TRUE,
			FALSE,
			FALSE,
			FALSE,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

