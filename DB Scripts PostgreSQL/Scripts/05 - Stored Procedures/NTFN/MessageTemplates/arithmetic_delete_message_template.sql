DROP FUNCTION IF EXISTS ntfn_arithmetic_delete_message_template;

CREATE OR REPLACE FUNCTION ntfn_arithmetic_delete_message_template
(
	vr_application_id			UUID,
	vr_template_id				UUID,
	vr_current_user_id			UUID,
	vr_now	 					TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE ntfn_message_templates AS mt
	SET	deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE mt.application_id = vr_application_id AND mt.template_id = vr_template_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

