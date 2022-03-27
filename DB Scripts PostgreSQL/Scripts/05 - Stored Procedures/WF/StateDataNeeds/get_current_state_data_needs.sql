DROP FUNCTION IF EXISTS wf_get_current_state_data_needs;

CREATE OR REPLACE FUNCTION wf_get_current_state_data_needs
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_state_id			UUID
)
RETURNS SETOF wf_state_data_need_ret_composite
AS
$$
DECLARE
	vr_state_ids				UUID[];
	vr_data_needs_type 			VARCHAR(20);
	vr_ref_data_needs_state_id 	UUID;
BEGIN
	SELECT INTO vr_data_needs_type, vr_ref_data_needs_state_id
				s.data_needs_type, s.ref_data_needs_state_id
	FROM wf_workflow_states AS s
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	IF vr_data_needs_type = 'RefState' THEN
		vr_state_ids := ARRAY(SELECT vr_ref_data_needs_state_id);
	ELSE
		vr_state_ids := ARRAY(SELECT vr_state_id);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM wf_p_get_state_data_needs(vr_application_id, vr_workflow_id, vr_state_ids);
END;
$$ LANGUAGE plpgsql;

