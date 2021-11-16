DROP FUNCTION IF EXISTS usr_login_attempt;

CREATE OR REPLACE FUNCTION usr_login_attempt
(
	vr_user_id 	UUID,
    vr_succeed	BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	UPDATE rv_membership AS mm
	SET failed_password_attempt_count = 
			CASE WHEN COALESCE(vr_succeed, FALSE) = FALSE THEN COALESCE(failed_password_attempt_count, 0) + 1 ELSE 0 END
	WHERE mm.user_id = vr_user_id;
		
	RETURN COALESCE((
		SELECT 	CASE 
					WHEN mm.failed_password_attempt_count <= 0 THEN 1 
					ELSE mm.failed_password_attempt_count 
				END::INTEGER AS "value"
		FROM rv_membership AS mm
		WHERE mm.user_id = vr_user_id
		LIMIT 1
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

