DROP FUNCTION IF EXISTS wf_set_state_data_need;

CREATE OR REPLACE FUNCTION wf_set_state_data_need
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_workflow_id		UUID,
	vr_state_id			UUID,
	vr_node_type_id		UUID,
	vr_pre_node_type_id	UUID,
	vr_form_id			UUID,
	vr_description 		VARCHAR(2000),
	vr_multiple_select 	BOOLEAN,
	vr_admin		 	BOOLEAN,
	vr_necessary	 	BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	
	IF vr_pre_node_type_id IS NOT NULL AND vr_pre_node_type_id <> vr_node_type_id THEN
		UPDATE wf_state_data_needs AS d
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE d.application_id = vr_application_id AND d.workflow_id = vr_workflow_id AND 
			d.state_id = vr_state_id AND d.node_type_id = vr_pre_node_type_id;
	END IF;
	
	IF EXISTS (
		SELECT 1
		FROM wf_state_data_needs AS d
		WHERE d.application_id = vr_application_id AND d.workflow_id = vr_workflow_id AND 
			d.state_id = vr_state_id AND d.node_type_id = vr_node_type_id
		LIMIT 1
	) THEN
		UPDATE wf_state_data_needs AS d
		SET description = vr_description,
			multiple_select = vr_multiple_select,
			"admin" = vr_admin,
			necessary = vr_necessary,
			deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE d.application_id = vr_application_id AND d.workflow_id = vr_workflow_id AND 
			d.state_id = vr_state_id AND d.node_type_id = vr_node_type_id;
	ELSE
		INSERT INTO wf_state_data_needs (
			application_id,
			"id",
			workflow_id,
			state_id,
			node_type_id,
			description,
			multiple_select,
			"admin",
			necessary,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_id,
			vr_workflow_id,
			vr_state_id,
			vr_node_type_id,
			vr_description,
			vr_multiple_select,
			vr_admin,
			vr_necessary,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result > 0 AND vr_form_id IS NOT NULL THEN
		vr_result := fg_p_set_form_owner(vr_application_id, vr_id, vr_form_id, vr_current_user_id, vr_now);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::INTEGER;
		END IF;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

