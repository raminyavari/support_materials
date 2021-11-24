DROP FUNCTION IF EXISTS qa_get_workflows;

CREATE OR REPLACE FUNCTION qa_get_workflows
(
	vr_application_id	UUID,
    vr_archive	 		BOOLEAN
)
RETURNS SETOF qa_workflow_ret_composite
AS
$$
DECLARE
	vr_ids	UUID;
BEGIN
	vr_ids := ARRAY(
		SELECT w.workflow_id
		FROM qa_workflows AS w
		WHERE w.application_id = vr_application_id AND w.deleted = COALESCE(vr_archive, FALSE)::BOOLEAN
		ORDER BY COALESCE(w.sequence_number, 1000000) ASC, w.creation_date ASC
	);
	
	RETURN QUERY
	SELECT *
	FROM qa_p_get_workflows_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

