DROP FUNCTION IF EXISTS rv_add_or_modify_application;

CREATE OR REPLACE FUNCTION rv_add_or_modify_application
(
	vr_application_id	UUID,
	vr_name		 		VARCHAR(255),
	vr_title		 	VARCHAR(255),
	vr_description 		VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM rv_applications AS "a"
		WHERE "a".application_id = vr_application_id
		LIMIT 1
	) THEN
		UPDATE rv_applications AS app
		SET title = gfn_verify_string(COALESCE(vr_title, '')),
			description = gfn_verify_string(COALESCE(vr_description, ''))
		WHERE app.application_id = vr_application_id;
	ELSE
		INSERT INTO rv_applications (
			application_id,
			application_name,
			lowered_application_name,
			title,
			description,
			creator_user_id,
			creation_date
		)
		VALUES (
			vr_application_id,
			gfn_verify_string(COALESCE(vr_name, '')),
			gfn_verify_string(COALESCE(vr_name, '')),
			gfn_verify_string(COALESCE(vr_title, '')),
			gfn_verify_string(COALESCE(vr_description, '')),
			vr_current_user_id,
			vr_now
		);
		
		IF vr_current_user_id IS NOT NULL AND vr_application_id IS NOT NULL THEN
			INSERT INTO usr_user_applications (application_id, user_id, creation_date)
			VALUES (vr_application_id, vr_current_user_id, vr_now);
		END IF;
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

