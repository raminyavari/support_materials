DROP FUNCTION IF EXISTS usr_get_friend_ids;

CREATE OR REPLACE FUNCTION usr_get_friend_ids
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_are_friends	 	BOOLEAN,
    vr_sent		 		BOOLEAN,
    vr_received	 		BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT rf.user_id AS "id"
	FROM usr_fn_get_friend_ids(vr_application_id, vr_user_id, vr_are_friends, vr_sent, vr_received) AS rf;
END;
$$ LANGUAGE plpgsql;

