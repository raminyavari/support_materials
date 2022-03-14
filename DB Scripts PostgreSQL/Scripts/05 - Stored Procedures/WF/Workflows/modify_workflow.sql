DROP FUNCTION IF EXISTS wf_modify_workflow;

CREATE OR REPLACE FUNCTION wf_modify_workflow
(
	vr_application_id	UUID,
    vr_workflow_id		UUID,
	vr_name			 	VARCHAR(255),
	vr_description	 	VARCHAR(2000),
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER DEFAULT 0;
BEGIN
	vr_name := gfn_verify_string(vr_name);
	vr_description := gfn_verify_string(vr_description);
	
	UPDATE wf_workflows AS w
	SET "name" = vr_name,
		description = vr_description,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

