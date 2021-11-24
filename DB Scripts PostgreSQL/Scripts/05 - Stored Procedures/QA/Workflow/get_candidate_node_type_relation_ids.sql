DROP FUNCTION IF EXISTS qa_get_candidate_node_type_relation_ids;

CREATE OR REPLACE FUNCTION qa_get_candidate_node_type_relation_ids
(
	vr_application_id							UUID,
    vr_workflow_id_or_question_id_or_answer_id	UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	IF vr_workflow_id_or_question_id_or_answer_id IS NOT NULL THEN
		vr_workflow_id_or_question_id_or_answer_id := COALESCE((
			SELECT q.workflow_id
			FROM qa_answers AS "a"
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = "a".question_id
			WHERE "a".application_id = vr_application_id AND "a".answer_id = vr_workflow_id_or_question_id_or_answer_id
			LIMIT 1
		), vr_workflow_id_or_question_id_or_answer_id);
		
		vr_workflow_id_or_question_id_or_answer_id := COALESCE((
			SELECT q.workflow_id
			FROM qa_questions AS q
			WHERE q.application_id = vr_application_id AND q.question_id = vr_workflow_id_or_question_id_or_answer_id
			LIMIT 1
		), vr_workflow_id_or_question_id_or_answer_id);
	END IF;
	
	SELECT cr.node_type_id AS "id"
	FROM qa_candidate_relations AS cr
	WHERE cr.application_id = vr_application_id AND 
		cr.workflow_id = vr_workflow_id AND cr.node_id IS NOT NULL AND cr.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

