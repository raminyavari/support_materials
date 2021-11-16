DROP FUNCTION IF EXISTS usr_get_friends;

CREATE OR REPLACE FUNCTION usr_get_friends
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_friend_ids		guid_table_type[],
    vr_mutuals_count 	BOOLEAN,
    vr_are_friends	 	BOOLEAN,
    vr_is_sender	 	BOOLEAN,
    vr_search_text	 	VARCHAR(1000),
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	friend_id				UUID,
	username				VARCHAR,
	first_name				VARCHAR,
	last_name				VARCHAR,
	request_date			TIMESTAMP,
	acception_date			TIMESTAMP,
	are_friends				BOOLEAN,
	is_sender				BOOLEAN,
	mutual_friends_count	INTEGER,
	"order"					INTEGER,
	total_count				INTEGER
)
AS
$$
DECLARE
	vr_f_ids_count	INTEGER;
BEGIN
	vr_f_ids_count := COALESCE(ARRAY_LENGTH(vr_friend_ids, 1), 0)::INTEGER;

	IF vr_f_ids_count > 0 THEN 
		vr_count := 1000000;
	END IF;
	
	RETURN QUERY
	WITH "data" AS 
	(
		SELECT 	un.user_id AS friend_id,
				un.username,
				un.first_name,
				un.last_name,
				fr.request_date,
				fr.acception_date,
				fr.are_friends,
				fr.is_sender,
				(ROW_NUMBER() OVER (ORDER BY 
									pgroonga_score(pr.tableoid, pr.ctid)::FLOAT DESC, 
									un.last_activity_date DESC, un.user_id DESC
								   )
				)::INTEGER AS seq
		FROM usr_profile AS pr
			INNER JOIN usr_view_friends AS fr
			ON fr.application_id = vr_application_id AND fr.friend_id = pr.user_id
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = fr.friend_id
		WHERE (COALESCE(vr_search_text, '') = '' OR pr.username &@~ vr_search_text OR
			  pr.first_name &@~ vr_search_text OR pr.last_name &@~ vr_search_text) AND
			fr.user_id = vr_user_id AND
			(vr_is_sender IS NULL OR fr.is_sender = vr_is_sender) AND
			(vr_f_ids_count = 0 OR fr.friend_id IN (SELECT x.value FROM UNNEST(vr_friend_ids) AS x)) AND
			(vr_are_friends IS NULL OR fr.are_friends = vr_are_friends)
	),
	total AS 
	(
		SELECT COUNT(d.friend_id) AS total_count
		FROM "data" AS d
	)
	
	SELECT	f.*,
			"t".total_count::INTEGER AS total_count
	FROM (
			SELECT 	my_friends.friend_id,
					MAX(my_friends.username) AS username,
					MAX(my_friends.first_name) AS first_name,
					MAX(my_friends.last_name) AS last_name,
					MAX(my_friends.request_date)::TIMESTAMP AS request_date,
					MAX(my_friends.acception_date)::TIMESTAMP AS acception_date,
					MAX(my_friends.are_friends::INTEGER)::BOOLEAN AS are_friends,
					MAX(my_friends.is_sender::INTEGER)::BOOLEAN AS is_sender,
					COUNT(fof.friend_of_friend)::INTEGER AS mutual_friends_count,
					MAX(my_friends.seq)::INTEGER AS "order"
			FROM "data" AS my_friends
				LEFT JOIN (
					SELECT x.friend_id AS friend, 
						CASE 
							WHEN uc.sender_user_id = x.friend_id THEN uc.receiver_user_id
							ELSE uc.sender_user_id
						END AS friend_of_friend
					FROM "data" AS x
						INNER JOIN usr_friends AS uc
						ON uc.application_id = vr_application_id AND 
							uc.are_friends = TRUE AND uc.deleted = FALSE AND 
							(uc.receiver_user_id = x.friend_id OR uc.sender_user_id = x.friend_id)
				) AS fof
				ON vr_mutuals_count = TRUE AND my_friends.friend_id = fof.friend_of_friend
			GROUP BY my_friends.friend_id
		) AS f
		CROSS JOIN total AS "t"
	WHERE f.order >= COALESCE(vr_lower_boundary, 0)
	ORDER BY f.order ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

