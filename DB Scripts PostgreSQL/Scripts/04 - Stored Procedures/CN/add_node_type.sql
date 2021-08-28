

DROP PROCEDURE IF EXISTS _cn_add_node_type;

CREATE OR REPLACE PROCEDURE _cn_add_node_type
(
	vr_application_id			UUID,
    vr_node_type_id 			UUID,
    vr_additional_id			VARCHAR(50),
    vr_name			 			VARCHAR(255),
    vr_parent_id				UUID,
    vr_setup_service	 		BOOLEAN,
    vr_template_node_type_id	UUID,
    vr_template_form_id 		UUID,
    vr_creator_user_id			UUID,
    vr_creation_date	 		TIMESTAMP,
	INOUT vr_result	 			INTEGER
)
AS
$$
DECLARE
	vr_form_id 		UUID;
	vr_form_title	VARCHAR(255);
BEGIN
	vr_result := 0;
	
	vr_name := gfn_verify_string(vr_name);
	
	IF vr_additional_id = N'' THEN
		vr_additional_id := NULL;
	END IF;
	
	IF vr_additional_id IS NULL OR NOT EXISTS(
		SELECT * 
		FROM cn_node_types
		WHERE application_id = vr_application_id AND additional_id = vr_additional_id
		LIMIT 1
	) THEN
		INSERT INTO cn_node_types(
			application_id,
			nodeType_id,
			template_type_id,
			additional_id,
			"name",
			parent_id,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_node_type_id,
			vr_template_node_type_id,
			vr_additional_id,
			vr_name,
			vr_parent_id,
			vr_creator_user_id,
			vr_creation_date,
			FALSE
		);
		
		IF COALESCE(vr_setup_service, 0) = 1 THEN
			vr_result := cn_p_initialize_service(vr_application_id, vr_node_type_id);
			
			UPDATE cn_services
			SET service_title = gfn_verify_string(vr_name)
			WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id;
			
			vr_form_id  := gen_random_uuid();
			
			vr_form_title := gfn_verify_string(vr_name) + N' - ' + 
				FLOOR((RAND() * (99998 - 10001)) + 10001)::VARCHAR(100);
			
			vr_result := fg_p_create_form(vr_application_id, vr_form_id, vr_template_form_id, 
				vr_form_title, vr_creator_user_id, vr_creation_date);
			
			vr_result := fg_p_set_form_owner(vr_application_id, vr_node_type_id, vr_form_id, 
											 vr_creator_user_id, vr_creation_date);
		END IF;
		
		vr_result := 1;
	ELSE
		vr_result := 0;
	END IF;

	COMMIT;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_add_node_type;

CREATE OR REPLACE FUNCTION cn_add_node_type
(
	vr_application_id			UUID,
    vr_node_type_id 			UUID,
    vr_additional_id			VARCHAR(50),
    vr_name			 			VARCHAR(255),
    vr_parent_id				UUID,
    vr_setup_service	 		BOOLEAN,
    vr_template_node_type_id	UUID,
    vr_template_form_id 		UUID,
    vr_creator_user_id			UUID,
    vr_creation_date	 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	CALL _cn_add_node_type(vr_application_id, vr_node_type_id, vr_additional_id, vr_name,
						   vr_parent_id, vr_setup_service, vr_template_node_type_id,
						   vr_template_form_id, vr_creator_user_id, vr_creation_date, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

