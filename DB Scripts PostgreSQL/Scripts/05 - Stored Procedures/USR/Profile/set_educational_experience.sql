DROP FUNCTION IF EXISTS usr_set_educational_experience;

CREATE OR REPLACE FUNCTION usr_set_educational_experience
(
	vr_application_id	UUID,
	vr_education_id		UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP,
	vr_school		 	VARCHAR(256),
	vr_study_field	 	VARCHAR(256),
	vr_level			VARCHAR(50),
	vr_graduate_degree	VARCHAR(50),
	vr_start_date	 	TIMESTAMP,
	vr_end_date	 		TIMESTAMP,
	vr_is_school	 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM usr_educational_experiences AS ex
		WHERE ex.application_id = vr_application_id AND ex.education_id = vr_education_id
		LIMIT 1
	) THEN
		UPDATE usr_educational_experiences AS ex
		SET user_id = vr_user_id,
			school = vr_school,
			study_field = vr_study_field,
			"level" = vr_level,
			graduate_degree = vr_graduate_degree,
			start_date = vr_start_date,
			end_eate = vr_end_date,
			creator_user_id = vr_current_user_id,
			creation_date = vr_now,
			is_school = vr_is_school
		WHERE ex.application_id = vr_application_id AND ex.education_id = vr_education_id;
	ELSE
		INSERT INTO usr_educational_experiences (
			application_id,
			education_id,
			user_id,
			school,
			study_field,
			"level",
			graduate_degree,
			start_date,
			end_date,
			creator_user_id,
			creation_date,
			is_school,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_education_id,
			vr_user_id,
			vr_school,
			vr_study_field,
			vr_level,
			vr_graduate_degree,
			vr_start_date,
			vr_end_date,
			vr_current_user_id,
			vr_now,
			vr_is_school,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

