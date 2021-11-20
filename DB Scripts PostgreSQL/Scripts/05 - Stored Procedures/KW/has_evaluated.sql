DROP FUNCTION IF EXISTS kw_has_evaluated;

CREATE OR REPLACE FUNCTION kw_has_evaluated
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID,
	vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM kw_question_answers AS "a"
		WHERE "a".application_id = vr_application_id AND "a".knowledge_id = vr_knowledge_id AND 
			"a".user_id = vr_user_id AND "a".deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

