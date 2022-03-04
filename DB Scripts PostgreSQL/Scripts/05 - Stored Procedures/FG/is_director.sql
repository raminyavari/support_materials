DROP FUNCTION IF EXISTS fg_is_director;

CREATE OR REPLACE FUNCTION fg_is_director
(
	vr_application_id	UUID,
	vr_instance_id		UUID,
	vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
DECLARE 
	vr_director_id	UUID;
	vr_is_admin 	BOOLEAN;
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM fg_form_instances AS i
		WHERE i.application_id = vr_application_id AND i.instance_id = vr_instance_id
		LIMIT 1
	) THEN
		vr_instance_id := (
			SELECT e.instance_id
			FROM fg_instance_elements AS e
			WHERE e.application_id = vr_application_id AND e.element_id = vr_instance_id
			LIMIT 1
		);
	END IF;
	
	SELECT INTO vr_director_id, vr_is_admin 
				i.director_id, i.admin
	FROM fg_form_instances AS i
	WHERE i.application_id = vr_application_id AND i.instance_id = vr_instance_id;
	
	IF vr_is_admin = FALSE THEN 
		vr_is_admin := NULL;
	END IF;
	
	IF vr_director_id IS NOT NULL AND vr_director_id = vr_user_id THEN
		RETURN TRUE;
	END IF;
	
	IF vr_director_id IS NOT NULL AND vr_director_id IN (
		SELECT * 
		FROM cn_p_get_member_node_ids(vr_application_id, vr_user_id, NULL, 'Accepted', vr_is_admin) AS x
	) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

