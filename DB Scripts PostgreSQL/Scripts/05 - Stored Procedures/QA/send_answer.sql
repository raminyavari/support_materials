DROP FUNCTION IF EXISTS qa_send_answer;

CREATE OR REPLACE FUNCTION qa_send_answer
(
	vr_application_id	UUID,
    vr_answer_id 		UUID,
    vr_question_id 		UUID,
    vr_answer_body	 	VARCHAR,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
    INSERT INTO qa_answers (
		application_id,
		answer_id,
        question_id,
        sender_user_id,
        send_date,
        answer_body,
        deleted
    )
    VALUES (
		vr_application_id,
		vr_answer_id,
        vr_question_id,
        vr_current_user_id,
        vr_now,
        gfn_verify_string(vr_answer_body),
        FALSE
    );
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

