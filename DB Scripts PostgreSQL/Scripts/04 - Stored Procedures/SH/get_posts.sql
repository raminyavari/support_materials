DROP FUNCTION IF EXISTS sh_get_posts;

CREATE OR REPLACE FUNCTION sh_get_posts
(
	vr_application_id	UUID,
    vr_owner_id	 		UUID,
    vr_user_id			UUID,
    vr_news		 		BOOLEAN,
    vr_max_date	 		TIMESTAMP,
    vr_min_date	 		TIMESTAMP,
    vr_count		 	INTEGER
)
RETURNS SETOF sh_post_ret_composite
AS
$$
DECLARE
	vr_share_ids 		UUID[];
	vr_min_posts_date 	TIMESTAMP;
	vr_cur_count 		INTEGER;
BEGIN
	IF vr_user_id IS NULL OR vr_user_id <> vr_owner_id OR COALESCE(vr_news, FALSE)::BOOLEAN = FALSE THEN
		vr_share_ids := ARRAY(
			SELECT ps.share_id 
			FROM sh_post_shares AS ps
			WHERE ps.application_id = vr_application_id AND ps.owner_id = vr_owner_id AND 
				  (vr_max_date IS NULL OR ps.send_date <= vr_max_date) AND 
				  (vr_min_date IS NULL OR ps.send_date >= vr_min_date) AND 
				  ps.deleted = FALSE
			ORDER BY ps.score_date DESC
			LIMIT vr_count
		);
	ELSE
		CREATE TEMP TABLE vr_temp_ids ("value" UUID, date TIMESTAMP);
		
		/* Public Posts */
		INSERT INTO vr_temp_ids
		SELECT ps.share_id, ps.score_date
		FROM sh_post_shares AS ps
		WHERE ps.application_id = vr_application_id AND 
			ps.owner_type = 'User' AND ps.privacy = 'Public' AND 
			(vr_max_date IS NULL OR ps.send_date <= vr_max_date) AND 
			(vr_min_date IS NULL OR ps.send_date >= vr_min_date) AND 
			ps.deleted = FALSE
		ORDER BY ps.score_date DESC
		LIMIT vr_count;
		/* end of Public Posts */
		
		vr_min_posts_date := (SELECT MIN("ref".date) FROM vr_temp_ids AS "ref");
		vr_cur_count := (SELECT COUNT(*) FROM vr_temp_ids);
		
		/* User's Posts */
		IF vr_count <= vr_cur_count THEN
			INSERT INTO vr_temp_ids
			SELECT ps.share_id, ps.score_date
			FROM sh_post_shares AS ps
			WHERE ps.application_id = vr_application_id AND 
				(ps.owner_id = vr_owner_id OR ps.sender_user_id = vr_user_id) AND 
				ps.owner_type = 'User' AND
				(vr_max_date IS NULL OR ps.send_date <= vr_max_date) AND 
				(vr_min_date IS NULL OR ps.send_date >= vr_min_date) AND 
				ps.send_date >= vr_min_posts_date AND ps.deleted = FALSE
			ORDER BY ps.score_date DESC
			LIMIT vr_count;
		ELSE
			INSERT INTO vr_temp_ids
			SELECT ps.share_id, ps.score_date
			FROM sh_post_shares AS ps
			WHERE ps.application_id = vr_application_id AND
				(ps.owner_id = vr_owner_id OR ps.sender_user_id = vr_user_id) AND 
				ps.owner_type = 'User' AND
				(vr_max_date IS NULL OR ps.send_date <= vr_max_date) AND
				(vr_min_date IS NULL OR ps.send_date >= vr_min_date) AND
				ps.deleted = FALSE
			ORDER BY ps.score_date DESC
			LIMIT vr_count;
		END IF;
		/* end of User's Posts */
		
		vr_min_posts_date = (SELECT MIN("ref".date) FROM vr_temp_ids AS "ref");
		vr_cur_count = (SELECT COUNT(*) FROM vr_temp_ids);
		
		/* User's Friend's Posts */
		CREATE TEMP TABLE vr_friend_ids ("value" UUID primary key);
		
		INSERT INTO vr_friend_ids
		SELECT "ref".user_id
		FROM usr_fn_get_friend_ids(vr_application_id, vr_user_id, TRUE, TRUE, TRUE) AS "ref";
		
		IF vr_count <= vr_cur_count THEN
			INSERT INTO vr_temp_ids
			SELECT ps.share_id, ps.score_date
			FROM vr_friend_ids AS friends
				INNER JOIN sh_post_shares AS ps
				ON (ps.sender_user_id = friends.value OR ps.owner_id = friends.value)
			WHERE ps.application_id = vr_application_id AND ps.owner_type = 'User' AND
				  ps.privacy = 'Friends' AND 
				  (vr_max_date IS NULL OR ps.send_date <= vr_max_date) AND 
				  (vr_min_date IS NULL OR ps.send_date >= vr_min_date) AND 
				  ps.send_date >= vr_min_posts_date AND
				  ps.deleted = FALSE
			ORDER BY ps.score_date DESC
			LIMIT vr_count;
		ELSE
			INSERT INTO vr_temp_ids
			SELECT ps.share_id, ps.score_date
			FROM vr_friend_ids AS friends
				INNER JOIN sh_post_shares AS ps
				ON (ps.sender_user_id = friends.value OR ps.owner_id = friends.value)
			WHERE ps.application_id = vr_application_id AND ps.owner_type = 'User' AND
				  ps.privacy = 'Friends' AND 
				  (vr_max_date IS NULL OR ps.send_date <= vr_max_date) AND 
				  (vr_min_date IS NULL OR ps.send_date >= vr_min_date) AND 
				  ps.deleted = FALSE
			ORDER BY ps.score_date DESC
			LIMIT vr_count;
		END IF;
		/* end of User's Friend's Posts */
		
		vr_share_ids := ARRAY(
			SELECT "ref".value 
			FROM vr_temp_ids AS "ref"
			GROUP BY "ref".value
			ORDER BY min("ref".date) DESC
			LIMIT vr_count	
		);
	END IF;

	RETURN QUERY
	SELECT *
	FROM sh_p_get_posts_by_ids(vr_application_id, vr_share_ids, vr_user_id);
END;
$$ LANGUAGE plpgsql;

