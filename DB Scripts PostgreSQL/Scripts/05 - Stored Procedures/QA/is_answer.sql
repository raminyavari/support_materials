DROP FUNCTION IF EXISTS qa_is_answer;

CREATE OR REPLACE FUNCTION qa_is_answer
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
		FROM qa_answers AS an
		WHERE an.application_id = vr_application_id AND an.answer_id = vr_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

