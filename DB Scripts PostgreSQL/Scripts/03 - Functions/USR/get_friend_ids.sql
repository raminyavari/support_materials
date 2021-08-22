DROP FUNCTION IF EXISTS usr_fn_get_friend_ids;

CREATE OR REPLACE FUNCTION usr_fn_get_friend_ids
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_are_friends	 	BOOLEAN,
    vr_sent		 		BOOLEAN,
    vr_received	 		BOOLEAN
)
RETURNS TABLE
(
	user_id	UUID
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT f.friend_id AS "id"
	FROM usr_view_friends AS f
	WHERE f.application_id = vr_application_id AND f.user_id = vr_user_id AND 
		(vr_are_friends IS NULL OR f.are_friends = vr_are_friends) AND
		((vr_received = TRUE AND f.is_sender = FALSE) OR (vr_sent = TRUE AND f.is_sender = TRUE));
END;
$$ LANGUAGE PLPGSQL;