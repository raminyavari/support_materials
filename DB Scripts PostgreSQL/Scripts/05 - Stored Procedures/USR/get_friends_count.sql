DROP FUNCTION IF EXISTS usr_get_friends_count;

CREATE OR REPLACE FUNCTION usr_get_friends_count
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_are_friends	 	BOOLEAN,
    vr_sent		 		BOOLEAN,
    vr_received	 		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(f.friend_id)
		FROM usr_view_friends AS f
		WHERE f.application_id = vr_application_id AND 
			f.user_id = vr_user_id AND (vr_are_friends IS NULL OR f.are_friends = vr_are_friends) AND
			((vr_sent = TRUE AND f.is_sender = TRUE) OR (vr_received = TRUE AND f.is_sender = FALSE))
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

