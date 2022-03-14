DROP FUNCTION IF EXISTS wf_create_workflow;

CREATE OR REPLACE FUNCTION wf_create_workflow
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
	
	IF EXISTS (
		SELECT 1
		FROM wf_workflows AS w
		WHERE w.application_id = vr_application_id AND w.name = vr_name AND w.deleted = TRUE
		LIMIT 1
	) THEN
		UPDATE wf_workflows AS w
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE w.application_id = vr_application_id AND w.name = vr_name AND w.deleted = TRUE;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
	END IF;
	
	IF EXISTS (
		SELECT 1
		FROM wf_workflows AS w
		WHERE w.application_id = vr_application_id AND w.name = vr_name AND w.deleted = FALSE
		LIMIT 1
	) THEN
		vr_result := -1::INTEGER;
	ELSE
		INSERT INTO wf_workflows (
			application_id,
			workflow_id,
			"name",
			description,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_workflow_id,
			vr_name,
			vr_description,
			vr_current_user_id,
			vr_now,
			FALSE
		);
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

