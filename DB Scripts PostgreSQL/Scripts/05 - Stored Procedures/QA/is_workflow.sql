DROP FUNCTION IF EXISTS qa_is_workflow;

CREATE OR REPLACE FUNCTION qa_is_workflow
(
	vr_application_id	UUID,
    vr_ids				guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT w.workflow_id AS "id"
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN qa_workflows AS w
		ON w.application_id = vr_application_id AND w.workflow_id = rf.value;
END;
$$ LANGUAGE plpgsql;

