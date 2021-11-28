DROP FUNCTION IF EXISTS qa_get_knowledgable_user_ids;

CREATE OR REPLACE FUNCTION qa_get_knowledgable_user_ids
(
	vr_application_id	UUID,
	vr_question_id	 	UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT ru.user_id AS "id"
	FROM qa_related_users AS ru
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.user_id = ru.user_id AND un.is_approved = TRUE
	WHERE ru.application_id = vr_application_id AND 
		ru.question_id = vr_question_id AND ru.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

