DROP FUNCTION IF EXISTS wf_set_rejection_settings;

CREATE OR REPLACE FUNCTION wf_set_rejection_settings
(
	vr_application_id			UUID,
    vr_workflow_id				UUID,
	vr_state_id					UUID,
	vr_max_allowed_rejections 	INTEGER,
	vr_rejection_title		 	VARCHAR(255),
	vr_rejection_ref_state_id	UUID,
	vr_current_user_id			UUID,
	vr_now		 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_workflow_states AS s
	SET max_allowed_rejections = vr_max_allowed_rejections,
		rejection_title = vr_rejection_title,
		rejection_ref_state_id = vr_rejection_ref_state_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

