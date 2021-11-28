DROP FUNCTION IF EXISTS qa_get_question_asker_id;

CREATE OR REPLACE FUNCTION qa_get_question_asker_id
(
	vr_application_id	UUID,
    vr_question_id		UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT q.sender_user_id
		FROM qa_questions AS q
		WHERE q.application_id = vr_application_id AND q.question_id = vr_question_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

