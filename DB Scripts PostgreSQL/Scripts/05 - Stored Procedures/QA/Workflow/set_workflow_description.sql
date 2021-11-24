DROP FUNCTION IF EXISTS qa_set_workflow_description;

CREATE OR REPLACE FUNCTION qa_set_workflow_description
(
	vr_application_id	UUID,
    vr_workflow_id 		UUID,
    vr_description 		VARCHAR(2000),
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
	SET description = gfn_verify_string(vr_description),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

