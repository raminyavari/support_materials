DROP FUNCTION IF EXISTS qa_set_workflow_action_deadline;

CREATE OR REPLACE FUNCTION qa_set_workflow_action_deadline
(
	vr_application_id	UUID,
    vr_workflow_id 		UUID,
    vr_value		 	INTEGER,
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
	SET action_deadline = CASE WHEN COALESCE(vr_value, 0) <= 0 THEN 0 ELSE vr_value END::INTEGER
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

