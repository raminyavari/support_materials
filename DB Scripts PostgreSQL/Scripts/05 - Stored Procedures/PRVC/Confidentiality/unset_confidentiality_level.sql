DROP FUNCTION IF EXISTS prvc_unset_confidentiality_level;

CREATE OR REPLACE FUNCTION prvc_unset_confidentiality_level
(
	vr_application_id	UUID,
	vr_item_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE prvc_settings AS s
	SET confidentiality_id = NULL,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND s.object_id = vr_item_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

