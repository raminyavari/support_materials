DROP FUNCTION IF EXISTS wf_create_state_data_need_instance;

CREATE OR REPLACE FUNCTION wf_create_state_data_need_instance
(
	vr_application_id	UUID,
    vr_instance_id		UUID,
	vr_history_id		UUID,
	vr_node_id			UUID,
	vr_admin		 	BOOLEAN,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_form_instance_id	UUID;
	vr_result			INTEGER;
	vr_cursor_1			REFCURSOR;
	vr_cursor_2			REFCURSOR;
BEGIN
	INSERT INTO wf_state_data_need_instances (
		application_id,
		instance_id,
		history_id,
		node_id,
		"admin",
		filled,
		attachment_id,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_instance_id,
		vr_history_id,
		vr_node_id,
		vr_admin,
		FALSE,
		gen_random_uuid(),
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	
	IF vr_form_id IS NOT NULL THEN
		vr_form_instance_id := gen_random_uuid();
		
		DROP TABLE IF EXISTS instances_43534;
		
		CREATE TEMP TABLE instances_43534 OF form_instance_table_type;
		
		INSERT INTO instances_43534 (
			instance_id, 
			form_id, 
			owner_id, 
			director_id, 
			"admin"
		)
		VALUES (
			vr_form_instance_id, 
			vr_form_id, 
			vr_instance_id, 
			vr_node_id, 
			vr_admin
		);
		
		vr_result := fg_p_create_form_instance(
			vr_application_id, 
			ARRAY(
				SELECT x
				FROM instances_43534 AS x
			), 
			vr_current_user_id, 
			vr_now
		);
			
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN;
		END IF;
	END IF;
	
	-- Send Dashboards
	SELECT 	x.result, x.dashboards
	INTO 	vr_result, vr_cursor_2
	FROM wf_p_send_dashboards(vr_application_id, vr_history_id, NULL, NULL, NULL, NULL, NULL, vr_instance_id, vr_now) AS x;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'CannotDetermineDirector');
		RETURN;
	END IF;
	-- end of Send Dashboards
	
	OPEN vr_cursor_1 FOR
	SELECT 1::INTEGER;
	
	RETURN NEXT vr_cursor_2;
	RETURN NEXT vr_cursor_1;
END;
$$ LANGUAGE plpgsql;

