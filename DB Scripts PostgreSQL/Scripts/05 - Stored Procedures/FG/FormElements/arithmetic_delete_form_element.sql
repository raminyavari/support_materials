DROP FUNCTION IF EXISTS fg_arithmetic_delete_form_element;

CREATE OR REPLACE FUNCTION fg_arithmetic_delete_form_element
(
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_extended_form_elements AS e
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

