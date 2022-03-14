DROP FUNCTION IF EXISTS wf_get_workflows;

CREATE OR REPLACE FUNCTION wf_get_workflows
(
	vr_application_id	UUID
)
RETURNS SETOF wf_workflow_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT w.workflow_id
		FROM wf_workflows AS w
		WHERE w.application_id = vr_application_id AND w.deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM wf_p_get_workflows_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

