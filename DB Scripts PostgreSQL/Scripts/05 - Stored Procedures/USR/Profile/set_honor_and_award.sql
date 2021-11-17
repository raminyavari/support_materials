DROP FUNCTION IF EXISTS usr_set_honor_and_award;

CREATE OR REPLACE FUNCTION usr_set_honor_and_award
(
	vr_application_id	UUID,
	vr_honor_id			UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP,
	vr_title		 	VARCHAR(512),
	vr_occupation	 	VARCHAR(512),
	vr_issuer		 	VARCHAR(512),
	vr_issue_date	 	TIMESTAMP,
	vr_description 		VARCHAR
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM usr_honors_and_awards AS ha
		WHERE ha.application_id = vr_application_id AND ha.id = vr_honor_id
		LIMIT 1
	) THEN
		UPDATE usr_honors_and_awards AS ha
		SET user_id = vr_user_id,
			title = vr_title,
			occupation = vr_occupation,
			issuer = vr_issuer,
			issue_date = vr_issue_date,
			description = vr_description,
			creator_user_id = vr_current_user_id,
			creation_date = vr_now
		WHERE ha.application_id = vr_application_id AND ha.id = vr_honor_id;
	ELSE
		INSERT INTO usr_honors_and_awards (
			application_id,
			"id",
			user_id,
			title,
			occupation,
			issuer,
			issue_date,
			description,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_honor_id,
			vr_user_id,
			vr_title,
			vr_occupation,
			vr_issuer,
			vr_issue_date,
			vr_description,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

