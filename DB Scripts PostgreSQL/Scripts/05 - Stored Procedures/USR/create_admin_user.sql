DROP FUNCTION IF EXISTS usr_create_admin_user;

CREATE OR REPLACE FUNCTION usr_create_admin_user
(
	vr_application_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_user_id			UUID;
	vr_admin_role_id	UUID;
BEGIN
	IF NOT EXISTS(
		SELECT * 
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND un.lowered_username = 'admin'
		LIMIT 1
	) THEN
		vr_admin_role_id := (
			SELECT r.role_id
			FROM rv_roles AS r
			WHERE r.application_id = vr_application_id AND r.lowered_role_name = 'admins'
			LIMIT 1
		);
	
		IF vr_admin_role_id IS NULL THEN
			vr_admin_role_id := gen_random_uuid();
		
			INSERT INTO rv_roles (
				application_id,
				role_id,
				role_name,
				lowered_role_name
			)
			VALUES (
				vr_application_id,
				vr_admin_role_id,
				'Admins',
				'admins'
			);
		END IF;
		
		vr_user_id := gen_random_uuid();
	
		INSERT INTO rv_users (user_id, username, 
			lowered_username, mobile_alias, is_anonymous, last_activity_date) 
		VALUES (vr_user_id, 'admin', 'admin', NULL, FALSE, '2013-04-23 12:10:21.000'::TIMESTAMP);
		
		INSERT INTO rv_users_in_roles (user_id, role_id)
		VALUES (vr_user_id, vr_admin_role_id);
		
		INSERT INTO usr_profile ( 
			user_id, 
			first_name,
			lastname, 
			birthdate
		) 
		VALUES (vr_user_id, 'سیستم', 'مدیر', NULL);
			
		INSERT INTO rv_membership (user_id, "password", 
			password_format, password_salt, mobile_pin, email, lowered_email, 
			password_question, password_answer, is_approved, is_locked_out, create_date, 
			last_login_date, last_password_changed_date, last_lockout_date, 
			failed_password_attempt_count, failed_password_attempt_window_start, 
			failed_password_answer_attempt_count, failed_password_answer_attempt_window_start, "comment") 
		VALUES (vr_user_id, 'hzpljiwy35CCLSmxIuTk49mhDI4=', 1, '6rG7hIBmkJ6cfestS4Ycow==', NULL, NULL, NULL, NULL, 
			NULL, TRUE, FALSE, '2013-04-23 12:10:21.000'::TIMESTAMP, '2013-04-23 12:10:21.000'::TIMESTAMP, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, '1754-01-01 00:00:00.000'::TIMESTAMP, 0, 
			'1754-01-01 00:00:00.000'::TIMESTAMP, 0, '1754-01-01 00:00:00.000'::TIMESTAMP, NULL);
			
		INSERT INTO usr_user_applications (application_id, user_id)
		VALUES (vr_application_id, vr_user_id);
	END IF;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

