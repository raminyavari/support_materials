DROP FUNCTION IF EXISTS qa_is_answer_owner;

CREATE OR REPLACE FUNCTION qa_is_answer_owner
(
	vr_application_id	UUID,
    vr_answer_id		UUID,
	vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM qa_answers AS ans
		WHERE ans.application_id = vr_application_id AND 
			ans.answer_id = vr_answer_id AND ans.sender_user_id = vr_user_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

