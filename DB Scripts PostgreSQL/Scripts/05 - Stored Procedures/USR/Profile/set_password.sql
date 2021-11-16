DROP FUNCTION IF EXISTS usr_set_password;

CREATE OR REPLACE FUNCTION usr_set_password
(
	vr_user_id 				UUID,
    vr_password		 		VARCHAR(255),
    vr_password_salt 		VARCHAR(255),
    vr_encrypted_password 	VARCHAR(255),
    vr_auto_generated	 	BOOLEAN,
    vr_now			 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE rv_membership AS mm
	SET "password" = vr_password,
		password_salt = vr_password_salt,
		is_locked_out = FALSE
	WHERE mm.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1;
	END IF;
	
	vr_result := usr_p_save_password_history(vr_user_id, vr_encrypted_password, vr_auto_generated, vr_now);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

