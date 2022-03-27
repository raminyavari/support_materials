DROP FUNCTION IF EXISTS wf_get_first_workflow_state;

CREATE OR REPLACE FUNCTION wf_get_first_workflow_state
(
	vr_application_id	UUID,
	vr_workflow_id		UUID
)
RETURNS SETOF wf_workflow_state_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT wfs.state_id
		FROM wf_workflow_states AS wfs
		WHERE wfs.application_id = vr_application_id AND 
			wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE AND
			NOT EXISTS (
				SELECT 1 
				FROM wf_state_connections AS sc
					INNER JOIN wf_workflow_states AS rf
					ON rf.application_id = vr_application_id AND 
						rf.state_id = sc.in_state_id AND rf.deleted = FALSE
				WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
					sc.out_state_id = wfs.state_id AND sc.deleted = FALSE
				LIMIT 1
			)
	);

	RETURN QUERY
	SELECT *
	FROM wf_p_get_workflow_states(vr_application_id, vr_workflow_id, vr_ids)
	WHERE COALESCE(ARRAY_LENGTH(vr_ids, 1), 0) = 1;
END;
$$ LANGUAGE plpgsql;

