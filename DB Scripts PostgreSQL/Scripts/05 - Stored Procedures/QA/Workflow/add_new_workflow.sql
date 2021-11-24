DROP FUNCTION IF EXISTS qa_add_new_workflow;

CREATE OR REPLACE FUNCTION qa_add_new_workflow
(
	vr_application_id	UUID,
    vr_workflow_id 		UUID,
    vr_name		 		VARCHAR(200),
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_seq_no	INTEGER;
	vr_result	INTEGER;
BEGIN
	vr_seq_no := COALESCE((
		SELECT MAX(w.sequence_number) 
		FROM qa_workflows AS w
		WHERE w.application_id = vr_application_id
	), 0)::INTEGER + 1::INTEGER;

    INSERT INTO qa_workflows (
		application_id,
		workflow_id,
        "name",
        sequence_number,
        initial_check_needed,
        final_confirmation_needed,
        removable_after_confirmation,
        disable_comments,
        disable_question_likes,
        disable_answer_likes,
        disable_comment_likes,
        disable_best_answer,
        creator_user_id,
        creation_date,
        deleted
    )
    VALUES (
		vr_application_id,
		vr_workflow_id,
        gfn_verify_string(vr_name),
        vr_seq_no,
        FALSE,
        FALSE,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        vr_current_user_id,
        vr_now,
        FALSE
    );
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

