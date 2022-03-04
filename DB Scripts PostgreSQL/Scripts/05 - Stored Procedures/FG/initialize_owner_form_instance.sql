DROP FUNCTION IF EXISTS fg_initialize_owner_form_instance;

CREATE OR REPLACE FUNCTION fg_initialize_owner_form_instance
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS UUID
AS
$$
DECLARE
	vr_instance_id	UUID;
	vr_result		INTEGER;
BEGIN
	IF vr_form_id IS NULL THEN
		SELECT INTO vr_form_id 
					o.form_id
		FROM fg_form_owners AS o
		WHERE o.application_id = vr_application_id AND 
			o.owner_id = vr_owner_id AND o.deleted = FALSE
		LIMIT 1;
	END IF;
	
	IF vr_form_id IS NULL THEN
		SELECT INTO vr_form_id 
					fo.form_id
		FROM fg_form_owners AS fo
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_type_id = fo.owner_id
		WHERE fo.application_id = vr_application_id AND 
			nd.node_id = vr_owner_id AND fo.deleted = FALSE;
	END IF;
	
	IF vr_form_id IS NULL OR vr_owner_id IS NULL THEN
		RETURN NULL::UUID;
	ELSE
		SELECT INTO vr_instance_id 
					i.instance_id
		FROM fg_form_instances AS i
		WHERE i.application_id = vr_application_id AND 
			i.form_id = vr_form_id AND i.owner_id = vr_owner_id AND i.deleted = FALSE
		LIMIT 1;
			
		IF vr_instance_id IS NOT NULL THEN 
			RETURN vr_instance_id;
		ELSE
			vr_instance_id := gen_random_uuid();
			
			DROP TABLE IF EXISTS instances_98374;
			
			CREATE TEMP TABLE instances_98374 OF form_instance_table_type;
			
			INSERT INTO instances_98374 (instance_id, form_id, owner_id, director_id, "admin")
			VALUES (vr_instance_id, vr_form_id, vr_owner_id, NULL, NULL);
			
			vr_result := fg_p_create_form_instance(
				vr_application_id, 
				ARRAY(
					SELECT x
					FROM instances_98374 AS x
				), 
				vr_current_user_id, 
				vr_now
			);
				
			IF vr_result > 0 THEN 
				RETURN vr_instance_id;
			ELSE
				RETURN NULL::UUID;
			END IF;
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;

