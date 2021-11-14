DROP FUNCTION IF EXISTS usr_get_friendship_status;

CREATE OR REPLACE FUNCTION usr_get_friendship_status
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_other_user_ids	guid_table_type[],
    vr_mutuals_count	BOOLEAN
)
RETURNS TABLE (
	user_id					UUID,
	is_friend				BOOLEAN,
	is_sender				BOOLEAN,
	mutual_friends_count	INTEGER
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_other_user_ids) AS x
	);

	RETURN QUERY
	WITH "data" AS 
	(
		SELECT	o AS user_id,
				COALESCE(f.are_friends, FALSE)::BOOLEAN AS is_friend,
				COALESCE(f.is_sender, FALSE)::BOOLEAN AS is_sender
		FROM UNNEST(vr_ids) AS o
			INNER JOIN usr_view_friends AS f
			ON f.user_id = vr_user_id AND f.friend_id = o
		WHERE f.application_id = vr_application_id
	),
	updated AS
	(
		SELECT 	d.*,
				COALESCE("m".mutual_friends_count, 0)::INTEGER AS mutual_friends_count
		FROM "data" AS d
			LEFT JOIN usr_fn_get_mutual_friends_count(vr_application_id, vr_user_id, vr_ids) AS "m"
			ON vr_mutuals_count = TRUE AND "m".user_id = d.user_id
	)
	SELECT 	u.user_id,
			u.is_friend,
			u.is_sender,
			u.mutual_friends_count
	FROM updated AS u;
END;
$$ LANGUAGE plpgsql;

