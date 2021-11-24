DROP FUNCTION IF EXISTS qa_set_workflow_disable_question_likes;

CREATE OR REPLACE FUNCTION qa_set_workflow_disable_question_likes
(
	vr_application_id	UUID,
    vr_workflow_id 		UUID,
    vr_value		 	BOOLEAN,
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_workflows AS w
	SET disable_question_likes = COALESCE(vr_value, FALSE)::BOOLEAN
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

