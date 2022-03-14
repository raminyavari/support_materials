DROP FUNCTION IF EXISTS wf_p_get_workflows_by_ids;

CREATE OR REPLACE FUNCTION wf_p_get_workflows_by_ids
(
	vr_application_id	UUID,
    vr_workflow_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_workflow_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT wf.workflow_id,
		   wf.name,
		   wf.description,
		   vr_total_count
	FROM UNNEST(vr_workflow_ids) AS x
		INNER JOIN wf_workflows AS wf
		ON wf.application_id = vr_application_id AND wf.workflow_id = x
	ORDER BY wf.creation_date DESC;
END;
$$ LANGUAGE plpgsql;

