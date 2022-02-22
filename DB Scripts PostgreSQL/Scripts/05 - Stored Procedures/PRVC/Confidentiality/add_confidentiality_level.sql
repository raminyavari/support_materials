DROP FUNCTION IF EXISTS prvc_add_confidentiality_level;

CREATE OR REPLACE FUNCTION prvc_add_confidentiality_level
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_level_id	 		INTEGER,
	vr_title		 	VARCHAR(256),
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_title := gfn_verify_string(vr_title);
	
	IF EXISTS (
		SELECT 1 
		FROM prvc_confidentiality_levels AS cl
		WHERE cl.application_id = vr_application_id AND 
			cl.level_id = vr_level_id AND cl.deleted = FALSE
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'LevelCodeAlreadyExists');
		RETURN -1;
	END IF;
	
	INSERT INTO prvc_confidentiality_levels (
		application_id,
		"id",
		level_id,
		title,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_id,
		vr_level_id,
		vr_title,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

