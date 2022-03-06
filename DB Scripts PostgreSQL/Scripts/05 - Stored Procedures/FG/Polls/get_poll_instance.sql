DROP FUNCTION IF EXISTS fg_get_poll_instance;

CREATE OR REPLACE FUNCTION fg_get_poll_instance
(
	vr_application_id		UUID,
	vr_poll_id				UUID,
	vr_copy_from_poll_id	UUID,
	vr_owner_id				UUID,
	vr_current_user_id		UUID,
	vr_now		 			TIMESTAMP
)
RETURNS UUID
AS
$$
DECLARE
	vr_form_id 		UUID;
	vr_instance_id 	UUID;
	vr_result		INTEGER DEFAULT 0;
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM fg_polls AS "p"
		WHERE "p".poll_id = vr_poll_id
		LIMIT 1
	) THEN
		vr_result := fg_p_add_poll(vr_application_id, vr_poll_id, vr_copy_from_poll_id, 
								   vr_owner_id, NULL, vr_current_user_id, vr_now);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN NULL::UUID;
		END IF;
	END IF;
	
	vr_form_id := (
		SELECT fo.form_id
		FROM fg_polls AS "p"
			INNER JOIN fg_form_owners AS fo
			ON fo.application_id = vr_application_id AND 
				fo.owner_id = "p".poll_id AND fo.deleted = FALSE
		WHERE "p".application_id = vr_application_id AND "p".poll_id = vr_copy_from_poll_id
		LIMIT 1
	);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN NULL::UUID;
	END IF;
	
	vr_instance_id := (
		SELECT fi.instance_id
		FROM fg_form_instances AS fi
		WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND
			fi.director_id = vr_current_user_id AND fi.deleted = FALSE
		ORDER BY fi.creation_date DESC
		LIMIT 1
	);
	
	IF vr_instance_id IS NULL THEN
		vr_instance_id := gen_random_uuid();
		
		DROP TABLE IF EXISTS instances_63478;	
		
		CREATE TEMP TABLE instances_63478 OF form_instance_table_type;
			
		INSERT INTO instances_63478 (
			instance_id, 
			form_id, 
			owner_id, 
			director_id, 
			"admin"
		)
		VALUES (
			vr_instance_id, 
			vr_form_id, 
			vr_poll_id, 
			vr_current_user_id, 
			FALSE
		);
		
		vr_result := fg_p_create_form_instance(
			vr_application_id, 
			ARRAY(
				SELECT x
				FROM instances_63478 AS x
			), 
			vr_current_user_id, 
			vr_now
		);
			
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN NULL::UUID;
		END IF;
	END IF;
	
	RETURN vr_instance_id;
END;
$$ LANGUAGE plpgsql;

