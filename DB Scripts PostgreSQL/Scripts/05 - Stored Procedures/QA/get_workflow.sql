DROP FUNCTION IF EXISTS qa_get_workflow;

CREATE OR REPLACE FUNCTION qa_get_workflow
(
	vr_application_id							UUID,
    vr_workflow_id_or_question_id_or_answer_id	UUID
)
RETURNS SETOF qa_workflow_ret_composite
AS
$$
DECLARE
	vr_ids	UUID;
BEGIN
	vr_workflow_id_or_question_id_or_answer_id := COALESCE((
		SELECT q.workflow_id
		FROM qa_answers AS "a"
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = "a".question_id
		WHERE "a".application_id = vr_application_id AND "a".answer_id = vr_workflow_id_or_question_id_or_answer_id
		LIMIT 1
	), vr_workflow_id_or_question_id_or_answer_id);
	
	vr_ids := ARRAY(
		SELECT vr_workflow_id_or_question_id_or_answer_id
	);
	
	RETURN QUERY
	SELECT *
	FROM qa_p_get_workflows_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

