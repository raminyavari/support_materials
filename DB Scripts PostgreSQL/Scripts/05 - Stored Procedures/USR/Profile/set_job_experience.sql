DROP FUNCTION IF EXISTS usr_set_job_experience;

CREATE OR REPLACE FUNCTION usr_set_job_experience
(
	vr_application_id	UUID,
	vr_job_id			UUID,
    vr_user_id			UUID,
    vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP,
    vr_title		 	VARCHAR(256),
    vr_employer	 		VARCHAR(256),
    vr_start_date	 	TIMESTAMP,
    vr_end_date	 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM usr_job_experiences AS ex
		WHERE ex.application_id = vr_application_id AND ex.job_id = vr_job_id
		LIMIT 1
	) THEN
		UPDATE usr_job_experiences AS ex
		SET user_id = vr_user_id,
			title = vr_title,
			employer = vr_employer,
			start_date = vr_start_date,
			end_date = vr_end_date
		WHERE ex.application_id = vr_application_id AND ex.job_id = vr_job_id;
	ELSE
		INSERT INTO usr_job_experiences (
			application_id,
			job_id,
			user_id,
			title,
			employer,
			start_date,
			end_date,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_job_id,
			vr_user_id,
			vr_title,
			vr_employer,
			vr_start_date,
			vr_end_date,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

