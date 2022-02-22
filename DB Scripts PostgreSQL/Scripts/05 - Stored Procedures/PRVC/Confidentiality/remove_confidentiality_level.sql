DROP FUNCTION IF EXISTS prvc_remove_confidentiality_level;

CREATE OR REPLACE FUNCTION prvc_remove_confidentiality_level
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE prvc_confidentiality_levels AS cl
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE cl.application_id = vr_application_id AND cl.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

