DROP FUNCTION IF EXISTS qa_get_answer_sender_ids;

CREATE OR REPLACE FUNCTION qa_get_answer_sender_ids
(
	vr_application_id	UUID,
    vr_question_id		UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
    SELECT ans.sender_user_id AS "id"
	FROM qa_answers AS ans
	WHERE ans.application_id = vr_application_id AND 
		ans.question_id = vr_question_id AND ans.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

