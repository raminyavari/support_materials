DROP FUNCTION IF EXISTS wf_get_states;

CREATE OR REPLACE FUNCTION wf_get_states
(
	vr_application_id	UUID,
	vr_workflow_id		UUID
)
RETURNS SETOF wf_state_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	IF vr_workflow_id IS NULL THEN
		vr_ids := ARRAY(
			SELECT s.state_id
			FROM wf_states AS s
			WHERE s.application_id = vr_application_id AND s.deleted = FALSE
		);
	ELSE
		vr_ids := ARRAY(
			SELECT s.state_id
			FROM wf_workflow_states AS s
			WHERE s.application_id = vr_application_id AND 
				s.workflow_id = vr_workflow_id AND s.deleted = FALSE
		);
	END IF;

	RETURN QUERY
	SELECT *
	FROM wf_p_get_states_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

