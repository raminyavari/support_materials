DROP FUNCTION IF EXISTS qa_is_related_user;

CREATE OR REPLACE FUNCTION qa_is_related_user
(
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM qa_related_users AS ru
		WHERE ru.application_id = vr_application_id AND 
			ru.user_id = vr_user_id AND ru.question_id = vr_question_id AND ru.deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

