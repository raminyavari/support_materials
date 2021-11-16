DROP FUNCTION IF EXISTS usr_set_last_activity_date;

CREATE OR REPLACE FUNCTION usr_set_last_activity_date
(
	vr_user_id	UUID,
    vr_now		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE rv_users AS u
	SET last_activity_date = vr_now
	WHERE u.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

