DROP FUNCTION IF EXISTS qa_get_answers;

CREATE OR REPLACE FUNCTION qa_get_answers
(
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_current_user_id	UUID
)
RETURNS SETOF qa_answer_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT "a".answer_id
		FROM qa_answers AS "a"
		WHERE "a".application_id = vr_application_id AND 
			"a".question_id = vr_question_id AND "a".deleted = FALSE
		ORDER BY "a".send_date ASC, "a".answer_id ASC
	);
	
	RETURN QUERY
	SELECT *
	FROM qa_p_get_answers_by_ids(vr_application_id, vr_ids, vr_current_user_id);
END;
$$ LANGUAGE plpgsql;

