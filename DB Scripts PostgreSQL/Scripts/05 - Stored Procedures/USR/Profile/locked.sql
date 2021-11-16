DROP FUNCTION IF EXISTS usr_locked;

CREATE OR REPLACE FUNCTION usr_locked
(
	vr_user_id 	UUID,
    vr_locked	BOOLEAN,
    vr_now		TIMESTAMP	
)
RETURNS REFCURSOR
AS
$$
DECLARE
	vr_result	INTEGER;
	vr_cursor	REFCURSOR;
BEGIN
	IF vr_locked IS NULL THEN
		OPEN vr_cursor FOR
		SELECT 	mm.user_id, 
				mm.is_locked_out, 
				mm.last_lockout_date, 
				mm.is_approved
		FROM rv_membership AS mm
		WHERE mm.user_id = vr_user_id
		LIMIT 1;
		
		RETURN vr_cursor;
	ELSE
		UPDATE rv_membership AS mm
		SET is_locked_out = vr_locked,
			last_lockout_date = CASE WHEN vr_locked = TRUE THEN vr_now ELSE mm.last_lockout_date END,
			failed_password_attempt_count = 
				(CASE WHEN mm.is_locked_out = vr_locked THEN mm.failed_password_attempt_count ELSE 0::INTEGER END)
		WHERE mm.user_id = vr_user_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		OPEN vr_cursor FOR
		SELECT vr_result;
		
		RETURN vr_cursor;
	END IF;
END;
$$ LANGUAGE plpgsql;

