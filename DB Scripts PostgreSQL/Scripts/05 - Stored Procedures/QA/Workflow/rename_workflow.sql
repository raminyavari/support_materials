DROP FUNCTION IF EXISTS qa_rename_workflow;

CREATE OR REPLACE FUNCTION qa_rename_workflow
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
	vr_result	INTEGER;
BEGIN
	UPDATE qa_workflows AS w
	SET "name" = gfn_verify_string(vr_name),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

