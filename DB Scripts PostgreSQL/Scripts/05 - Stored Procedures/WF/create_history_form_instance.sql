DROP FUNCTION IF EXISTS wf_create_history_form_instance;

CREATE OR REPLACE FUNCTION wf_create_history_form_instance
(
	vr_application_id	UUID,
	vr_history_id		UUID,
	vr_out_state_id		UUID,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS UUID
AS
$$
DECLARE
	vr_form_owner_id	UUID;
	vr_form_director_id UUID;
	vr_form_instance_id UUID;
	vr_admin 			BOOLEAN;
	vr_workflow_id 		UUID;
	vr_state_id 		UUID;
	vr_result			INTEGER;
BEGIN
	vr_form_instance_id := gen_random_uuid();
	
	SELECT 	COALESCE(h.director_node_id, h.director_user_id), 
			h.workflow_id,
			h.state_id
	INTO	vr_form_director_id,
			vr_workflow_id,
			vr_state_id
	FROM wf_history AS h
	WHERE h.application_id = vr_application_id AND h.history_id = vr_history_id;
	
	SELECT 	s.admin 
	INTO	vr_admin
	FROM wf_workflow_states AS s
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id
	LIMIT 1;
	
	IF EXISTS (
		SELECT 1
		FROM wf_history_form_instances AS f
		WHERE f.application_id = vr_application_id AND 
			f.history_id = vr_history_id AND f.out_state_id = vr_out_state_id
		LIMIT 1
	) THEN
		UPDATE wf_history_form_instances AS f
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE f.application_id = vr_application_id AND 
			f.history_id = vr_history_id AND f.out_state_id = vr_out_state_id;
	ELSE
		vr_form_owner_id := gen_random_uuid();
		
		INSERT INTO wf_history_form_instances (
			application_id,
			history_id,
			out_state_id,
			forms_id,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_history_id,
			vr_out_state_id,
			vr_form_owner_id,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN NULL;
	END IF;
	
	IF vr_form_owner_id IS NULL THEN
		vr_form_owner_id := (
			SELECT f.forms_id 
			FROM wf_history_form_instances AS f
			WHERE f.application_id = vr_application_id AND 
				f.history_id = vr_history_id AND f.out_state_id = vr_out_state_id
			LIMIT 1
		);
	END IF;
	
	DROP TABLE IF EXISTS instances_63475;
	
	CREATE TEMP TABLE instances_63475 OF form_instance_table_type;
	
	INSERT INTO instances_63475 (
		instance_id, 
		form_id, 
		owner_id, 
		director_id, 
		"admin"
	)
	VALUES (
		vr_form_instance_id, 
		vr_form_id, 
		vr_form_owner_id, 
		vr_form_director_id, 
		vr_admin
	);
	
	vr_result := fg_p_create_form_instance(
		vr_application_id, 
		ARRAY(
			SELECT x
			FROM instances_63475 AS x
		), 
		vr_current_user_id, 
		vr_now
	);
		
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN NULL;
	END IF;
	
	RETURN vr_form_instance_id;
END;
$$ LANGUAGE plpgsql;

