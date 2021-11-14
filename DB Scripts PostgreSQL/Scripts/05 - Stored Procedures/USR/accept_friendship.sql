DROP FUNCTION IF EXISTS usr_accept_friendship;

CREATE OR REPLACE FUNCTION usr_accept_friendship
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_sender_user_id	UUID,
    vr_acception_date 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_friends AS f
	SET are_friends = TRUE,
		acception_date = vr_acception_date
	WHERE f.application_id = vr_application_id AND 
		f.sender_user_id = vr_sender_user_id AND f.receiver_user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

