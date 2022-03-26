DROP FUNCTION IF EXISTS wf_set_state_director;

CREATE OR REPLACE FUNCTION wf_set_state_director
(
	vr_application_id	UUID,
    vr_workflow_id		UUID,
	vr_stateID			UUID,
	vr_response_type	VARCHAR(20),
	vr_ref_state_id		UUID,
	vr_node_id			UUID,
	vr_admin			BOOLEAN,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wf_workflow_states AS s
	SET response_type = vr_response_type,
		ref_state_id = vr_ref_state_id,
		node_id = vr_node_id,
		"admin" = vr_admin,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

