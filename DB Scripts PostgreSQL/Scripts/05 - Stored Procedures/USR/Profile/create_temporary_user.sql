DROP FUNCTION IF EXISTS usr_create_temporary_user;

CREATE OR REPLACE FUNCTION usr_create_temporary_user
(
    vr_user_id 				UUID,
    vr_username		 		VARCHAR(255),
    vr_first_name		 	VARCHAR(255),
    vr_last_name			VARCHAR(255),
    vr_password		 		VARCHAR(255),
    vr_password_salt	 	VARCHAR(255),
    vr_encrypted_password	VARCHAR(255),
    vr_pass_auto_generated 	BOOLEAN,
    vr_email			 	VARCHAR(255),
    vr_phone_number			VARCHAR(50),
    vr_now			 		TIMESTAMP,
    vr_expiration_date	 	TIMESTAMP,
    vr_activation_code		VARCHAR(255),
    vr_invitation_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_username := gfn_verify_string(vr_username);
	vr_first_name := gfn_verify_string(vr_first_name);
	vr_last_name := gfn_verify_string(vr_last_name);
	
	IF EXISTS (
		SELECT 1 
		FROM usr_view_users AS u
		WHERE u.lowered_username = LOWER(vr_username)
		LIMIT 1
	) OR EXISTS (
		SELECT 1 
		FROM usr_temporary_users AS u
		WHERE LOWER(u.username) = LOWER(vr_username) AND
			(u.expiration_date IS NOT NULL AND u.expiration_date >= vr_now)
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'UserNameAlreadyExists');
		RETURN -1;
	END IF;
	
	IF EXISTS (
		SELECT 1 
		FROM usr_email_addresses  AS e
		WHERE LOWER(e.email_address) = LOWER(vr_email)
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'EmailAddressAlreadyExists');
		RETURN -1;
	END IF;
	
	IF EXISTS (
		SELECT 1 
		FROM usr_phone_numbers  AS e
		WHERE LOWER(e.phone_number) = LOWER(vr_phone_number)
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'PhoneNumberAlreadyExists');
		RETURN -1;
	END IF;
	
	
	INSERT INTO usr_temporary_users (
		user_id,
		username,
		first_name,
		last_name,
		"password",
		password_salt,
		email,
		phone_number,
		creation_date,
		expiration_date,
		activation_code
	)
	VALUES (
		vr_user_id,
		vr_username,
		vr_first_name,
		vr_last_name,
		vr_password,
		vr_password_salt,
		vr_email,
		vr_phone_number,
		vr_now,
		vr_expiration_date,
		vr_activation_code
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1;
	END IF;
	
	IF vr_invitationID IS NOT NULL THEN
		UPDATE usr_invitations AS i
		SET created_user_id = vr_user_id
		WHERE i.id = vr_invitation_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;

		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1;
		END IF;
	END IF;
	
	vr_result := usr_p_save_password_history(vr_user_id, vr_encrypted_password, vr_pass_auto_generated, vr_now);
		
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1;
	END IF;
	
	SELECT 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

