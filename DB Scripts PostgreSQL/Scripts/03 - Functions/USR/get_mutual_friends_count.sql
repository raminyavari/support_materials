DROP FUNCTION IF EXISTS usr_fn_get_mutual_friends_count;

CREATE OR REPLACE FUNCTION usr_fn_get_mutual_friends_count
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_other_user_ids	UUID[]
)
RETURNS TABLE
(
	user_id					UUID,
    mutual_friends_count	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT o.value AS user_id, COUNT(f.friend_id) AS mutuals_count
	FROM usr_view_friends AS f
		INNER JOIN vr_other_user_ids AS o
		INNER JOIN usr_view_friends AS f2
		ON f2.application_id = vr_application_id AND f2.user_id = o.value
		ON f2.friend_id = f.friend_id
	WHERE f.application_id = vr_application_id AND f.user_id = vr_user_id AND 
		f.are_friends = TRUE AND f2.are_friends = TRUE AND 
		f2.friend_id <> f.user_id AND f.friend_id <> f2.user_id
	GROUP BY f.user_id, o.value;
END;
$$ LANGUAGE PLPGSQL;