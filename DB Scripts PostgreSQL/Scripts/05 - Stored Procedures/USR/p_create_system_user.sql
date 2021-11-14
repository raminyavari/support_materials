DROP FUNCTION IF EXISTS usr_p_create_system_user;

CREATE OR REPLACE FUNCTION usr_p_create_system_user
(
	vr_application_id	UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF NOT EXISTS(
		SELECT * 
		FROM users_normal AS un
		WHERE (vr_application_id IS NULL OR un.application_id = vr_application_id) AND 
			un.lowered_username = 'system'
		LIMIT 1
	) THEN
		INSERT INTO rv_users (user_id, username, 
			lowered_username, mobile_alias, is_anonymous, last_activity_date) 
		VALUES (vr_user_id, 'system', 'system', NULL, FALSE, '2013-04-23 12:10:21.000'::TIMESTAMP);
		
		INSERT INTO usr_profile ( 
			user_id, 
			first_name,
			lastname, 
			birthdate
		) 
		VALUES (vr_user_id, 'رای', 'ون', NULL);
			
		INSERT INTO rv_membership (user_id, "password", 
			password_format, password_salt, mobile_pin, email, lowered_email, 
			password_question, password_answer, is_approved, is_locked_out, create_date, 
			last_login_date, last_password_changed_date, last_lockout_date, 
			failed_password_attempt_count, failed_password_attempt_window_start, 
			failed_password_answer_attempt_count, failed_password_answer_attempt_window_start, "comment") 
		VALUES (vr_user_id, 'saS+wizpq8cetvwnCAdCAHek3Ls=', 1, '0QnG9cGvuzB99qo+ycdaow==', NULL, NULL, NULL, NULL, 
			NULL, TRUE, FALSE, '2013-04-23 12:10:21.000'::TIMESTAMP, '2013-04-23 12:10:21.000'::TIMESTAMP, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, '1754-01-01 00:00:00.000'::TIMESTAMP, 0, 
			'1754-01-01 00:00:00.000'::TIMESTAMP, 0, '1754-01-01 00:00:00.000'::TIMESTAMP, NULL);
			
		IF vr_application_id IS NOT NULL THEN
			INSERT INTO usr_user_applications (application_id, user_id)
			VALUES (vr_application_id, vr_user_id);
		END IF;
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

