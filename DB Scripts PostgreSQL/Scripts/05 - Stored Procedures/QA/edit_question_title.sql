DROP FUNCTION IF EXISTS qa_edit_question_title;

CREATE OR REPLACE FUNCTION qa_edit_question_title
(
	vr_application_id	UUID,
    vr_question_id 		UUID,
    vr_title			VARCHAR(500),
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
	SET title = gfn_verify_string(vr_title),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE q.application_id = vr_application_id AND q.question_id = vr_question_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

