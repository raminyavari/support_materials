DROP FUNCTION IF EXISTS fg_get_form_instance_owner_id;

CREATE OR REPLACE FUNCTION fg_get_form_instance_owner_id
(
	vr_application_id				UUID,
	vr_instance_id_or_element_id	UUID
)
RETURNS UUID
AS
$$
DECLARE
	vr_owner_id	UUID;
BEGIN
	SELECT vr_owner_id = fi.owner_id
	FROM fg_form_instances AS fi
	WHERE fi.application_id = vr_application_id AND 
		fi.instance_id = vr_instance_id_or_element_id
	LIMIT 1;
	
	IF vr_owner_id IS NULL THEN
		SELECT vr_owner_id = fi.owner_id
		FROM fg_instance_elements AS ie
			INNER JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.instance_id = ie.instance_id
		WHERE ie.application_id = vr_application_id AND 
			ie.element_id = vr_instance_id_or_element_id
		LIMIT 1;
	END IF;
	
	RETURN vr_owner_id;
END;
$$ LANGUAGE plpgsql;

