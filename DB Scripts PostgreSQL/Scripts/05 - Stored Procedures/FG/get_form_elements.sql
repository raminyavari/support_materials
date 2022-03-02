DROP FUNCTION IF EXISTS fg_get_form_elements;

CREATE OR REPLACE FUNCTION fg_get_form_elements
(
	vr_application_id	UUID,
	vr_form_id			UUID,
	vr_owner_id			UUID,
	vr_type				VARCHAR(50)
)
RETURNS SETOF fg_form_element_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	IF vr_form_id IS NULL AND vr_owner_id IS NOT NULL THEN
		SELECT vr_form_id = o.form_id
		FROM fg_form_owners AS o
		WHERE o.application_id = vr_application_id AND 
			o.owner_id = vr_owner_id AND o.deleted = FALSE
		LIMIT 1;
	END IF;
	
	vr_ids := ARRAY(
		SELECT e.element_id
		FROM fg_extended_form_elements AS e
		WHERE e.application_id = vr_application_id AND e.form_id = vr_form_id AND 
			(vr_type IS NULL OR e.type = vr_type) AND e.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM fg_p_get_form_elements(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

