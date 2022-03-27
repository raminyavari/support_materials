DROP FUNCTION IF EXISTS wf_p_get_workflow_connection_forms;

CREATE OR REPLACE FUNCTION wf_p_get_workflow_connection_forms
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_connection_form_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT scf.workflow_id,
		   scf.in_state_id,
		   scf.out_state_id,
		   scf.form_id,
		   ef.title AS form_title,
		   scf.description,
		   scf.necessary,
		   vr_total_count
	FROM UNNEST(vr_in_state_ids) AS x
		INNER JOIN wf_state_connection_forms AS scf
		ON scf.in_state_id = x
		LEFT JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = scf.form_id
	WHERE scf.application_id = vr_application_id AND 
		scf.workflow_id = vr_workflow_id AND scf.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

