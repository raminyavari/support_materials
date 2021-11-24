DROP FUNCTION IF EXISTS qa_set_workflow_node_select_type;

CREATE OR REPLACE FUNCTION qa_set_workflow_node_select_type
(
	vr_application_id	UUID,
    vr_workflow_id 		UUID,
    vr_value		 	VARCHAR(50),
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
	SET node_select_type = vr_value
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

