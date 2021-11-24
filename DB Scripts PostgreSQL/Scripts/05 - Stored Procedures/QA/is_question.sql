DROP FUNCTION IF EXISTS qa_is_question;

CREATE OR REPLACE FUNCTION qa_is_question
(
	vr_application_id	UUID,
    vr_id				UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM qa_questions AS q
		WHERE q.application_id = vr_application_id AND q.question_id = vr_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

