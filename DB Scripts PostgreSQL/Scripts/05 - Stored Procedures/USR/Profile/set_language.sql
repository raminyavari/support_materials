DROP FUNCTION IF EXISTS usr_set_language;

CREATE OR REPLACE FUNCTION usr_set_language
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_language_name 	VARCHAR(256),
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP,
	vr_level		 	VARCHAR(50)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_language_id	UUID;
	vr_result		INTEGER;
BEGIN
	vr_language_name := gfn_verify_string(vr_language_name);
	
	vr_language_id := (
		SELECT l.language_id
		FROM usr_language_names AS l
		WHERE l.application_id = vr_application_id AND l.language_name = vr_language_name
		LIMIT 1
	);
	
	IF (vr_language_id IS NULL) THEN
		vr_language_id := gen_random_uuid();
		
		INSERT INTO usr_language_names(
			application_id,
			language_id,
			language_name
		)
		VALUES (
			vr_application_id,
			vr_language_id,
			vr_language_name
		);
	END IF;
		
	IF EXISTS(
		SELECT 1
		FROM usr_user_languages AS l
		WHERE l.application_id = vr_application_id AND l.id = vr_id
		LIMIT 1
	) THEN
		UPDATE usr_user_languages AS l
		SET user_id = vr_user_id,
			language_id = vr_language_id,
			"level"	= vr_level,
			creator_user_id = vr_current_user_id,
			creation_date = vr_now
		WHERE l.application_id = vr_application_id AND l.id = vr_id;
	ELSE
		INSERT INTO usr_user_languages (
			application_id,
			"id",
			language_id,
			user_id,
			"level",
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES	(
			vr_application_id,
			vr_id,
			vr_language_id,
			vr_user_id,
			vr_level,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

