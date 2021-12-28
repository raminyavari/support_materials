DROP FUNCTION IF EXISTS de_update_users;

CREATE OR REPLACE FUNCTION de_update_users
(
	vr_application_id	UUID,
	vr_users			exchange_user_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_error_message	VARCHAR;
	vr_result			INTEGER;
BEGIN	
	DROP TABLE IF EXISTS vr_temp_users_15863;
	
	CREATE TEMP TABLE vr_temp_users_15863 (
		"id" 			SERIAL, 
		user_id 		UUID, 
		new_username 	VARCHAR(255),
		first_name 		VARCHAR(255), 
		last_name 		VARCHAR(255), 
		employment_type VARCHAR(50)
	);

	INSERT INTO vr_temp_users_15863 (
		user_id, 
		new_username, 
		first_name, 
		last_name, 
		employment_type
	)
	SELECT 	usr.user_id, 
			rf.new_username, 
			gfn_verify_string(rf.first_name),
			gfn_verify_string(rf.last_name), 
			rf.employment_type
	FROM UNNEST(vr_users) AS rf
		INNER JOIN rv_users AS usr
		ON usr.lowered_username = LOWER(rf.username)
		INNER JOIN usr_user_applications AS app
		ON app.application_id = vr_application_id AND app.user_id = usr.user_id;
	
	-- Create New Users
	DROP TABLE IF EXISTS vr_new_users_09823;
	DROP TABLE IF EXISTS vr_first_passwords_09823;
	
	CREATE TEMP TABLE vr_new_users_09823 OF exchange_user_table_type;
	CREATE TEMP TABLE vr_first_passwords_09823 OF guid_string_table_type;
	
	INSERT INTO vr_new_users_09823 (
		user_id, 
		username, 
		first_name, 
		last_name, 
		"password", 
		password_salt, 
		encrypted_password
	)
	SELECT 	gen_random_uuid(), 
			rf.username, 
			rf.first_name, 
			rf.last_name, 
			rf.password, 
			rf.password_salt, 
			rf.encrypted_password
	FROM UNNEST(vr_users) AS rf
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(rf.username) AND
			COALESCE(rf.new_username, '') = ''
	WHERE COALESCE(rf.password, '') <> '' AND COALESCE(rf.password_salt, '') <> '' AND
		COALESCE(rf.encrypted_password, '') <> '' AND un.user_id IS NULL;
	
	INSERT INTO vr_first_passwords_09823 (
		"first_value", 
		second_value
	)
	SELECT u.user_id, u.encrypted_password
	FROM vr_new_users_09823 AS u;
	
	SELECT 	vr_result = rf.result,
			vr_error_message = rf.error_message
	FROM usr_p_create_users(vr_application_id, ARRAY(
			SELECT x
			FROM vr_new_users_09823 AS x
		), vr_now) AS rf
	LIMIT 1;
	
	vr_result := usr_p_save_password_history_bulk(ARRAY(
		SELECT x
		FROM vr_first_passwords_09823 AS x
	), TRUE, vr_now);
	-- end of Create New Users
	
	-- Reset passwords
	DROP TABLE IF EXISTS vr_change_pass_users_52837;
	DROP TABLE IF EXISTS vr_changed_passwords_52837;
	
	CREATE TEMP TABLE vr_change_pass_users_52837 OF exchange_user_table_type;
	CREATE TEMP TABLE vr_changed_passwords_52837 OF guid_string_table_type;
	
	INSERT INTO vr_change_pass_users_52837 (
		user_id, 
		"password", 
		password_salt, 
		encrypted_password
	)
	SELECT 	un.user_id, 
			rf.password, 
			rf.password_salt, 
			rf.encrypted_password
	FROM UNNEST(vr_users) AS rf
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(rf.username)
		LEFT JOIN vr_first_passwords_09823 AS f
		ON f.first_value = un.user_id
	WHERE rf.reset_password = TRUE AND f.first_value IS NULL AND 
		COALESCE(rf.password, '') <> '' AND COALESCE(rf.password_salt, '') <> '';
	
	UPDATE rv_membership
	SET "password" = "c".password,
		password_salt = "c".password_salt
	FROM vr_change_pass_users_52837 AS "c"
		INNER JOIN rv_membership AS "m"
		ON "m".user_id = "c".user_id;
	
	INSERT INTO vr_changed_passwords_52837(
		"first_value", 
		second_value
	)
	SELECT u.user_id, u.encrypted_password
	FROM vr_change_pass_users_52837 AS u;
	
	vr_result := usr_p_save_password_history_bulk(ARRAY(
		SELECT x
		FROM vr_changed_passwords_52837 AS x
	), TRUE, vr_now);
	-- end of Reset passwords
	
	
	UPDATE usr_profile
	SET first_name = rf.first_name
	FROM vr_temp_users_15863 AS rf
		INNER JOIN usr_profile AS "p"
		ON "p".user_id = rf.user_id
	WHERE COALESCE(rf.first_name, '') <> '';
	
	UPDATE usr_profile
	SET last_name = rf.last_name
	FROM vr_temp_users_15863 AS rf
		INNER JOIN usr_profile AS "p"
		ON "p".user_id = rf.user_id
	WHERE COALESCE(rf.last_name, '') <> '';
	
	UPDATE usr_user_applications
	SET employment_type = rf.employment_type
	FROM vr_temp_users_15863 AS rf
		INNER JOIN usr_user_applications AS "p"
		ON "p".application_id = vr_application_id AND "p".user_id = rf.user_id
	WHERE COALESCE(rf.employment_type, '') <> '';
	
	UPDATE usr_profile
	SET username = x.new_username,
		lowered_username = LOWER(x.new_username)
	FROM (
			SELECT u.*
			FROM vr_temp_users_15863 AS u
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND 
					un.lowered_username = LOWER(u.new_username) AND u.user_id <> un.user_id
			WHERE COALESCE(u.new_username, '') <> '' AND un.user_id IS NULL
		) AS x
		INNER JOIN usr_profile AS usr
		ON usr.user_id = x.user_id;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

