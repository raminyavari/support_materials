DROP FUNCTION IF EXISTS usr_get_friend_suggestions;

CREATE OR REPLACE FUNCTION usr_get_friend_suggestions
(
	vr_application_id	UUID,
    vr_user_id			UUID,
	vr_count		 	INTEGER,
    vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	user_id					UUID,
	first_name				VARCHAR,
	last_name				VARCHAR,
	mutual_friends_count	INTEGER,
	"order"					INTEGER,
	total_count				INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS 
	(
		SELECT	s.suggested_user_id AS user_id,
				un.first_name,
				un.last_name,
				(ROW_NUMBER() OVER (ORDER BY s.score DESC, s.suggested_user_id DESC))::INTEGER AS seq
		FROM usr_friend_suggestions AS s
			LEFT JOIN usr_view_friends AS f
			ON f.application_id = vr_application_id AND 
				f.user_id = s.user_id AND f.friend_id = s.suggested_user_id
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = s.suggested_user_id
		WHERE s.application_id = vr_application_id AND s.user_id = vr_user_id AND 
			un.is_approved = TRUE AND f.user_id IS NULL
	),
	data_mutual AS
	(
		SELECT 	x.user_id,
				x.first_name,
				x.last_name,
				COALESCE(o.mutual_friends_count, 0)::INTEGER AS mutual_friends_count,
				x.seq
		FROM usr_fn_get_mutual_friends_count(vr_application_id, vr_user_id, ARRAY(
				SELECT d.user_id
				FROM "data" AS d
			)) AS o
			INNER JOIN "data" AS x
			ON x.user_id = o.user_id
	),
	total AS 
	(
		SELECT COUNT(d.user_id) AS total_count
		FROM "data" AS d
	)
	SELECT	dt.user_id,
			dt.first_name,
			dt.last_name,
			dt.mutual_friends_count,
			dt.seq::INTEGER AS "order",
			"t".total_count::INTEGER
	FROM data_mutual AS dt
		CROSS JOIN total AS "t"
	WHERE dt.seq >= COALESCE(vr_lower_boundary, 0)
	ORDER BY dt.seq DESC
	LIMIT COALESCE(vr_count, 100000);
END;
$$ LANGUAGE plpgsql;

