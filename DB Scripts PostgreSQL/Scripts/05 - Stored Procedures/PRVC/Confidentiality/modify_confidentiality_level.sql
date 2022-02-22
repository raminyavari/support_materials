DROP FUNCTION IF EXISTS prvc_modify_confidentiality_level;

CREATE OR REPLACE FUNCTION prvc_modify_confidentiality_level
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_new_level_id		INTEGER,
	vr_new_title	 	VARCHAR(256),
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_new_title := gfn_verify_string(vr_new_title);
	
	IF EXISTS (
		SELECT 1 
		FROM prvc_confidentiality_levels AS cl
		WHERE cl.application_id = vr_application_id AND 
			cl.id <> vr_id AND cl.level_id = vr_new_level_id AND cl.deleted = FALSE
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'LevelCodeAlreadyExists');
		RETURN -1;
	END IF;
	
	UPDATE prvc_confidentiality_levels AS cl
	SET level_id = vr_new_level_id,
		title = vr_new_title,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE cl.application_id = vr_application_id AND cl.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

