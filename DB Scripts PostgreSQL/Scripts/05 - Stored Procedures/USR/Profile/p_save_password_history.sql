DROP FUNCTION IF EXISTS usr_p_save_password_history;

CREATE OR REPLACE FUNCTION usr_p_save_password_history
(
	vr_user_id 			UUID,
    vr_password	 		VARCHAR(255),
    vr_auto_generated	BOOLEAN,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO usr_passwords_history (
		user_id,
		"password",
		set_date,
		auto_generated
	)
	VALUES (
		vr_user_id,
		vr_password,
		vr_now,
		COALESCE(vr_auto_generated, FALSE)
	);

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

