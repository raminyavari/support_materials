DROP FUNCTION IF EXISTS usr_set_email_address;

CREATE OR REPLACE FUNCTION usr_set_email_address
(
	vr_email_id			UUID,
    vr_user_id 			UUID,
    vr_email_address	VARCHAR(100),
	vr_is_main_email 	BOOLEAN,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO usr_email_addresses (
		email_id,
		email_address,
		user_id,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_email_id,
		vr_email_address,
		vr_user_id,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_is_main_email = TRUE THEN
		UPDATE usr_profile AS pr
		SET main_email_id = vr_email_id
		WHERE pr.user_id = vr_user_id;
	END IF;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

