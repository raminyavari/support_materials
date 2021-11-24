DROP FUNCTION IF EXISTS qa_remove_question;

CREATE OR REPLACE FUNCTION qa_remove_question
(
	vr_application_id	UUID,
    vr_question_id 		UUID,
    vr_current_user_id	UUID,
    vr_now   			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_questions AS q
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE q.application_id = vr_application_id AND q.question_id = vr_question_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

