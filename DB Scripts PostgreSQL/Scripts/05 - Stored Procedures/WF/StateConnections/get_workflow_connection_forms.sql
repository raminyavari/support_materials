DROP FUNCTION IF EXISTS wf_get_workflow_connection_forms;

CREATE OR REPLACE FUNCTION wf_get_workflow_connection_forms
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_ids		guid_table_type[]
)
RETURNS SETOF wf_connection_form_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	IF COALESCE(ARRAY_LENGTH(vr_in_state_ids, 1), 0) = 0 THEN
		vr_ids := ARRAY(
			SELECT s.state_id
			FROM wf_workflow_states AS s
			WHERE s.application_id = vr_application_id AND 
				s.workflow_id = vr_workflow_id AND s.deleted = FALSE
		);
	ELSE
		vr_ids := ARRAY(
			SELECT DISTINCT rf.value
			FROM UNNEST(vr_in_state_ids) AS rf
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM wf_p_get_workflow_connection_forms(vr_application_id, vr_workflow_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

