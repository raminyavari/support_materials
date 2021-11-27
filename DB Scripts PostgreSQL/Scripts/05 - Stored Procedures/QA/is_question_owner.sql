DROP FUNCTION IF EXISTS qa_is_question_owner;

CREATE OR REPLACE FUNCTION qa_is_question_owner
(
	vr_application_id			UUID,
    vr_question_id_or_answer_id	UUID,
	vr_user_id					UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	vr_question_id_or_answer_id := COALESCE((
		SELECT ans.question_id
		FROM qa_answers AS ans
		WHERE ans.application_id = vr_application_id AND ans.answer_id = vr_question_id_or_answer_id
		LIMIT 1
	), vr_question_id_or_answer_id);
	
	RETURN COALESCE((
		SELECT TRUE
		FROM qa_questions AS q
		WHERE q.application_id = vr_application_id AND 
			q.question_id = vr_question_id_or_answer_id AND q.sender_user_id = vr_user_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

