DROP FUNCTION IF EXISTS usr_create_user;

CREATE OR REPLACE FUNCTION usr_create_user
(
	vr_application_id		UUID,
    vr_user_id 				UUID,
    vr_username		 		VARCHAR(255),
    vr_first_name			VARCHAR(255),
    vr_last_name			VARCHAR(255),
    vr_password		 		VARCHAR(255),
    vr_password_salt 		VARCHAR(255),
    vr_encrypted_password 	VARCHAR(255),
    vr_pass_auto_generated 	BOOLEAN,
    vr_email				VARCHAR(100),
    vr_phone_number			VARCHAR(50),
    vr_now			 		TIMESTAMP
)
RETURNS TABLE (
	"result"		INTEGER,
	error_message	VARCHAR
)
AS
$$
DECLARE
	vr_result	INTEGER;
	vr_message	VARCHAR;
BEGIN
	DROP TABLE IF EXISTS vr_users_29834;
	
	CREATE TEMP TABLE vr_users_29834 OF exchange_user_table_type;
	
	INSERT INTO vr_users_29834 (
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
	VALUES (
		vr_user_id, 
		vr_username, 
		vr_first_name, 
		vr_last_name,
		vr_password, 
		vr_password_salt, 
		vr_encrypted_password, 
		vr_email, 
		vr_phone_number
	);
	
	SELECT 	vr_result = x.result,
			vr_message = x.error_message
	FROM usr_p_create_users(vr_application_id, vr_users, vr_now) AS x;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(vr_result, vr_message);
		RETURN;
	END IF;
	
	vr_result := usr_p_save_password_history(vr_user_id, vr_encrypted_password, vr_pass_auto_generated, vr_now);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(vr_result);
		RETURN;
	END IF;
	
	RETURN QUERY
	SELECT vr_result, vr_message;
END;
$$ LANGUAGE plpgsql;

