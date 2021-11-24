DROP FUNCTION IF EXISTS qa_set_workflows_order;

CREATE OR REPLACE FUNCTION qa_set_workflows_order
(
	vr_application_id	UUID,
    vr_workflow_ids		guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_initial_count	INTEGER;
	vr_result			INTEGER;
BEGIN
	vr_workflow_ids := ARRAY(
		SELECT DISTINCT x
		FROM UNNEST(vr_workflow_ids) AS x
	);
	
	vr_initial_count := COALESCE(ARRAY_LENGTH(vr_workflow_ids, 1), 0)::INTEGER;

	WITH "data" AS
	(
		SELECT 	rf.seq::INTEGER AS seq,
				rf.value AS workflow_id
		FROM UNNEST(vr_workflow_ids) WITH ORDINALITY AS rf("value", seq)
		
		UNION ALL
		
		SELECT 	(ROW_NUMBER() OVER (ORDER BY w.sequence_number ASC))::INTEGER + vr_initial_count AS seq,
				w.workflow_id
		FROM UNNEST(vr_workflow_ids) AS rf
			RIGHT JOIN qa_workflows AS w
			ON w.application_id = vr_application_id AND w.workflow_id = rf.value
		WHERE w.application_id = vr_application_id AND rf.value IS NULL
		ORDER BY w.sequence_number ASC
	)
	UPDATE qa_workflows
	SET sequence_number = rf.seq
	FROM "data" AS rf
		INNER JOIN qa_workflows AS w
		ON w.workflow_id = rf.workflow_id
	WHERE w.application_id = vr_application_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

