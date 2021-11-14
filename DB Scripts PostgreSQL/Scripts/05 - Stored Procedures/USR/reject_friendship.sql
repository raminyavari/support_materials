DROP FUNCTION IF EXISTS usr_reject_friendship;

CREATE OR REPLACE FUNCTION usr_reject_friendship
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_friend_user_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_friends AS f
	SET are_friends = FALSE,
	 	deleted = TRUE
	WHERE f.application_id = vr_application_id AND (
			(f.sender_user_id = vr_user_id AND f.receiver_user_id = vr_friend_user_id) OR
			(f.sender_user_id = vr_friend_user_id AND f.receiver_user_id = vr_user_id)
		);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

