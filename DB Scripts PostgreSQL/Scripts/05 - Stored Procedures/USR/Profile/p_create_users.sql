DROP FUNCTION IF EXISTS usr_p_create_users;

CREATE OR REPLACE FUNCTION usr_p_create_users
(
	vr_application_id	UUID,
	vr_users			exchange_user_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS TABLE (
	"result"		INTEGER,
	error_message	VARCHAR
)
AS
$$
BEGIN
	IF vr_application_id IS NOT NULL AND EXISTS (
		SELECT 1 
		FROM UNNEST(vr_users) AS rf
			INNER JOIN users_normal AS u
			ON (vr_application_id IS NULL OR u.application_id = vr_application_id) AND 
				u.lowered_username = LOWER(rf.username)
		LIMIT 1
	) THEN
		RETURN QUERY
		SELECT -1::INTEGER, 'UserNameAlreadyExists'
	
		RETURN;
	ELSEIF vr_application_id IS NULL AND EXISTS (
		SELECT 1 
		FROM UNNEST(vr_users) AS rf
			INNER JOIN rv_users AS u
			ON u.lowered_username = LOWER(rf.username)
		LIMIT 1
	) THEN
		RETURN QUERY
		SELECT -1::INTEGER, 'UserNameAlreadyExists'
		
		RETURN;
	END IF;
	
	IF EXISTS (
		SELECT 1 
		FROM UNNEST(vr_users) AS rf
			INNER JOIN usr_email_addresses AS e
			ON LOWER(e.email_address) = LOWER(rf.email) AND e.deleted = FALSE
			INNER JOIN usr_profile AS "p"
			ON "p".user_id = e.user_id AND "p".main_email_id = e.email_id
		WHERE COALESCE(rf.email, '') <> ''
		LIMIT 1
	) THEN
		RETURN QUERY
		SELECT -1::INTEGER, 'EmailAddressAlreadyExists'
		
		RETURN;
	END IF;
	
	IF EXISTS (
		SELECT 1 
		FROM UNNEST(vr_users) AS rf
			INNER JOIN usr_phone_numbers AS e
			ON e.phone_number = LOWER(rf.phone_number) AND e.deleted = FALSE
			INNER JOIN usr_profile AS "p"
			ON "p".user_id = e.user_id AND "p".main_phone_id = e.number_id
		WHERE COALESCE(rf.phone_number, '') <> ''
		LIMIT 1
	) THEN
		RETURN QUERY
		SELECT -1::INTEGER, 'PhoneNumberAlreadyExists'
		
		RETURN;
	END IF;
	
	INSERT INTO rv_users (
		user_id,
		username,
		lowered_username,
		is_anonymous,
		last_activity_date
	)
	SELECT	rf.user_id, 
			rf.username, 
			LOWER(rf.username), 
			FALSE, 
			'1754-01-01 00:00:00.000'::TIMESTAMP
	FROM UNNEST(vr_users) AS rf
	WHERE rf.user_id IS NOT NULL AND COALESCE(rf.username, '') <> '' AND
		COALESCE(rf.password, '') <> '' AND COALESCE(rf.password_salt, '') <> '';

	INSERT INTO rv_membership (
		user_id,
		"password",
		password_format,
		password_salt,
		is_approved,
		is_locked_out,
		create_date,
		last_login_date,
		last_password_change_date,
		last_lockout_date,
		failed_password_attempt_count,
		failed_password_attempt_window_start,
		failed_password_answer_attempt_count,
		failed_password_answer_attempt_window_start
	)
	SELECT	rf.user_id,
			rf.password,
			1::INTEGER,
			rf.password_salt,
			TRUE,
			FALSE,
			vr_now,
			'1754-01-01 00:00:00.000'::TIMESTAMP,
			'1754-01-01 00:00:00.000'::TIMESTAMP,
			'1754-01-01 00:00:00.000'::TIMESTAMP,
			0::INTEGER,
			'1754-01-01 00:00:00.000'::TIMESTAMP,
			0::INTEGER,
			'1754-01-01 00:00:00.000'::TIMESTAMP
	FROM UNNEST(vr_users) AS rf
	WHERE rf.user_id IS NOT NULL AND COALESCE(rf.username, '') <> '' AND
		COALESCE(rf.password, '') <> '' AND COALESCE(rf.password_salt, '') <> '';
	
	INSERT INTO usr_profile (
		user_id, 
		first_name, 
		last_name
	)
	SELECT	rf.user_id,
			rf.first_name,
			rf.last_name
	FROM UNNEST(vr_users) AS rf
	WHERE rf.user_id IS NOT NULL AND COALESCE(rf.username, '') <> '' AND
		COALESCE(rf.password, '') <> '' AND COALESCE(rf.password_salt, '') <> '';
	
	IF vr_application_id IS NOT NULL THEN
		INSERT INTO usr_user_applications (
			application_id,
			user_id
		)
		SELECT	vr_application_id,
				rf.user_id
		FROM UNNEST(vr_users) AS rf
		WHERE rf.user_id IS NOT NULL AND COALESCE(rf.username, '') <> '' AND
			COALESCE(rf.password, '') <> '' AND COALESCE(rf.password_salt, '') <> '';
	END IF;
	
	
	-- Update Email Addresses
	DROP TABLE IF EXISTS vr_emails_45283;
	
	CREATE TEMP TABLE vr_emails_45283 (
		user_id 	UUID, 
		email_id 	UUID, 
		email 		VARCHAR(100)
	);
	
	INSERT INTO vr_emails_45283 (user_id, email_id, email)
	SELECT rf.user_id, gen_random_uuid(), rf.email
	FROM UNNEST(vr_users) AS rf
	WHERE rf.user_id IS NOT NULL AND 
		COALESCE(rf.username, '') <> '' AND COALESCE(rf.password, '') <> '' AND 
		COALESCE(rf.password_salt, '') <> '' AND COALESCE(rf.email, '') <> '';
		
	INSERT INTO usr_email_addresses (
		email_id, 
		user_id, 
		email_address,
		creator_user_id, 
		creation_date, 
		validated,
		deleted
	)
	SELECT	e.email_id,
			e.user_id,
			LOWER(e.email),
			e.user_id,
			vr_now,
			TRUE,
			FALSE
	FROM vr_emails_45283 AS e;
	
	UPDATE usr_profile
	SET main_email_id = e.email_id
	FROM vr_emails_45283 AS e
		INNER JOIN usr_profile AS "p"
		ON "p".user_id = e.user_id;
	-- end of Update Email Addresses
	
	
	-- Update Phone Numbers
	DROP TABLE IF EXISTS vr_numbers_45283;
	
	CREATE TEMP TABLE vr_numbers_45283 (
		user_id 		UUID, 
		number_id 		UUID, 
		phone_number 	VARCHAR(100)
	);
	
	INSERT INTO vr_numbers_45283 (user_id, number_id, phone_number)
	SELECT ref.user_id, gen_random_uuid(), ref.phone_number
	FROM UNNEST(vr_users) AS rf
	WHERE rf.user_id IS NOT NULL AND 
		COALESCE(rf.username, '') <> '' AND COALESCE(rf.password, '') <> '' AND 
		COALESCE(rf.password_salt, '') <> '' AND COALESCE(rf.phone_number, '') <> '';
		
	INSERT INTO usr_phone_numbers (
		number_id, 
		user_id, 
		phone_number,
		creator_user_id, 
		creation_date, 
		validated,
		deleted
	)
	SELECT	e.number_id,
			e.user_id,
			e.phone_number,
			e.user_id,
			vr_now,
			TRUE,
			FALSE
	FROM vr_numbers_45283 AS e;
	
	UPDATE usr_profile
		SET main_phone_id = e.number_id
	FROM vr_numbers_45283 AS e
		INNER JOIN usr_profile AS "p"
		ON "p".user_id = e.user_id;
	-- end of Update Phone Numbers
	
	RETURN QUERY
	SELECT 1::INTEGER, '';
END;
$$ LANGUAGE plpgsql;

