DROP FUNCTION IF EXISTS wf_set_state_connection_form;

CREATE OR REPLACE FUNCTION wf_set_state_connection_form
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_id		UUID,
	vr_out_state_id		UUID,
	vr_form_id			UUID,
	vr_description 		VARCHAR(4000),
	vr_necessary		BOOLEAN,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	vr_necessary := COALESCE(vr_necessary, FALSE)::BOOLEAN;
	
	IF EXISTS (
		SELECT 1
		FROM wf_state_connection_forms AS f
		WHERE f.application_id = vr_application_id AND f.workflow_id = vr_workflow_id AND 
			f.in_state_id = vr_in_state_id AND f.out_state_id = vr_out_state_id AND f.form_id = vr_form_id
		LIMIT 1
	) THEN
		UPDATE wf_state_connection_forms AS f
		SET description = vr_description,
			necessary = vr_necessary,
			deleted = FALSE,
			Last_modifier_user_id = vr_current_user_id,
			Last_modification_date = vr_now
		WHERE f.application_id = vr_application_id AND f.workflow_id = vr_workflow_id AND 
			f.in_state_id = vr_in_state_id AND f.out_state_id = vr_out_state_id AND f.form_id = vr_form_id;
	ELSE
		INSERT INTO wf_state_connection_forms (
			application_id,
			workflow_id,
			in_state_id,
			out_state_id,
			form_id,
			description,
			necessary,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_workflow_id,
			vr_in_state_id,
			vr_out_state_id,
			vr_form_id,
			vr_description,
			vr_necessary,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

