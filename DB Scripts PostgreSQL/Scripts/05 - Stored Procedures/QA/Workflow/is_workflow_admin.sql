DROP FUNCTION IF EXISTS qa_is_workflow_admin;

CREATE OR REPLACE FUNCTION qa_is_workflow_admin
(
	vr_application_id							UUID,
    vr_user_id									UUID,
    vr_workflow_id_or_question_id_or_answer_id	UUID
)
RETURNS BOOLEAN
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
	
	RETURN COALESCE((
		SELECT ad.user_id
		FROM qa_admins AS ad
		WHERE ad.application_id = vr_application_id AND ad.user_id = vr_user_id AND
			(
				(ad.workflow_id IS NULL AND vr_workflow_id_or_question_id_or_answer_id IS NULL) OR 
				(ad.workflow_id = vr_workflow_id_or_question_id_or_answer_id)
			) AND ad.deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

