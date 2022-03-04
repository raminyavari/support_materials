DROP FUNCTION IF EXISTS fg_set_form_element_necessity;

CREATE OR REPLACE FUNCTION fg_set_form_element_necessity
(
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_necessity	 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_extended_form_elements AS e
	SET necessary = vr_necessity
	WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

