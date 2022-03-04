DROP FUNCTION IF EXISTS fg_p_set_form_instance_as_filled;

CREATE OR REPLACE FUNCTION fg_p_set_form_instance_as_filled
(
	vr_application_id	UUID,
	vr_instance_id		UUID,
	vr_now	 			TIMESTAMP,
	vr_current_user_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_form_instances AS i
	SET filled = TRUE,
		filling_date = vr_now,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE i.application_id = vr_application_id AND 
		i.instance_id = vr_instance_id AND COALESCE(i.filled, FALSE)::BOOLEAN = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

