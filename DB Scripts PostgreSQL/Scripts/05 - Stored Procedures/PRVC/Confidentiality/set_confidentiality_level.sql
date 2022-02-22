DROP FUNCTION IF EXISTS prvc_set_confidentiality_level;

CREATE OR REPLACE FUNCTION prvc_set_confidentiality_level
(
	vr_application_id	UUID,
	vr_item_id			UUID,
	vr_level_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS	(
		SELECT 1
		FROM prvc_settings AS s
		WHERE s.application_id = vr_application_id AND s.object_id = vr_item_id
		LIMIT 1
	) THEN
		UPDATE prvc_settings AS s
		SET confidentiality_id = vr_level_id,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE s.application_id = vr_application_id AND s.object_id = vr_item_id;
	ELSE
		INSERT INTO prvc_settings (
			application_id,
			object_id,
			confidentiality_id,
			creator_user_id,
			creation_date
		)
		VALUES (
			vr_application_id,
			vr_item_id,
			vr_level_id,
			vr_current_user_id,
			vr_now
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

