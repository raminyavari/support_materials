DROP FUNCTION IF EXISTS fg_set_form_element_uniqueness;

CREATE OR REPLACE FUNCTION fg_set_form_element_uniqueness
(
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_value		 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_extended_form_elements AS e
	SET unique_value = vr_value
	WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

