DROP FUNCTION IF EXISTS usr_activate_temporary_user;

CREATE OR REPLACE FUNCTION usr_activate_temporary_user
(
    vr_activation_code	VARCHAR(255),
    vr_now		 		TIMESTAMP
)
RETURNS TABLE (
	"result"		INTEGER,
	error_message	VARCHAR
)
AS
$$
BEGIN
	DROP TABLE IF EXISTS vr_users_98345;
	
	CREATE TEMP TABLE vr_users_98345 OF exchange_user_table_type;

	WITH "data" AS
	(
		SELECT 	tu.user_id, 
				tu.username, 
				tu.first_name, 
				tu.last_name,
				tu.email, 
				tu.phone_number, 
				tu.password, 
				tu.password_salt,
				i.application_id
		FROM usr_temporary_users AS tu
			LEFT JOIN usr_invitations AS i
			ON i.created_user_id = tu.user_id
		WHERE tu.activation_code = vr_activation_code
		LIMIT 1
	)
	INSERT INTO vr_users_98345 (
		user_id, 
		username, 
		first_name, 
		last_name, 
		"password", 
		password_salt, 
		encrypted_password, 
		email, 
		phone_number
	)
	SELECT	d.user_id,
			d.username,
			d.first_name,
			d.last_name,
			d.password,
			d.password_salt,
			d.password,
			d.email,
			d.phone_number
	FROM "data" AS d
		LEFT JOIN usr_view_users AS un
		ON un.user_id = d.user_id
	WHERE un.user_id IS NULL;
	
	IF (SELECT COUNT(*) FROM vr_users_98345) = 0 THEN
		RETURN QUERY
		SELECT 1::INTEGER, '';
		
		RETURN;
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM usr_p_create_users(vr_application_id, ARRAY(
			SELECT x
			FROM vr_users_98345 AS x
		), vr_now);
END;
$$ LANGUAGE plpgsql;

