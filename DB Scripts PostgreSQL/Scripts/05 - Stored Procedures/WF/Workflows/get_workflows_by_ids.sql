DROP FUNCTION IF EXISTS wf_get_workflows_by_ids;

CREATE OR REPLACE FUNCTION wf_get_workflows_by_ids
(
	vr_application_id	UUID,
    vr_workflow_ids		guid_table_type[]
)
RETURNS SETOF wf_workflow_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_workflow_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM wf_p_get_workflows_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

