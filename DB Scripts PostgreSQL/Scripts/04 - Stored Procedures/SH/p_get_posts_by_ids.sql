DROP FUNCTION IF EXISTS sh_p_get_posts_by_ids;

CREATE OR REPLACE FUNCTION sh_p_get_posts_by_ids 
(
	vr_application_id	UUID,
    vr_share_ids		UUID[],
    vr_user_id			UUID
)
RETURNS SETOF sh_post_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT	ps.share_id AS post_id,
		   	ps.parent_share_id AS ref_post_id,
		   	"p".post_type_id,
		   	ps.description,
		   	"p".description AS original_description,
		   	"p".shared_object_id,
		   	ps.sender_user_id,
		   	ps.send_date,
		   	share_sender.first_name,
		   	share_sender.last_name,
		   	share_sender.job_title,
		   	"p".sender_user_id AS original_sender_user_id,
		   	"p".send_date AS original_send_date,
		   	post_sender.first_name AS original_first_name,
		   	post_sender.last_name AS original_last_name,
		   	post_sender.job_title AS original_job_title,
		   	ps.last_modification_date,
		   	ps.owner_id,
		   	ps.owner_type,
		   	ps.privacy,
		   	"p".has_picture,
		   	(
			   	SELECT COUNT(*) 
			   	FROM sh_comments AS "c"
				WHERE "c".application_id = vr_application_id AND 
					"c".share_id = ps.share_id AND "c".deleted = FALSE
		   	) AS comments_count,
		   	(
				SELECT COUNT(*) 
				FROM sh_share_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.share_id = ps.share_id AND l.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(*) 
				FROM sh_share_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.share_id = ps.share_id AND l.like = FALSE
			) AS dislikes_count,
			(
				SELECT l.like 
				FROM sh_share_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.share_id = ps.share_id AND l.user_id = vr_user_id
			) AS like_status
	FROM UNNEST(vr_share_ids) AS ex_id
		INNER JOIN sh_post_shares AS ps
		ON ps.application_id = vr_application_id AND ps.share_id = ex_id
		INNER JOIN sh_posts AS "p"
		ON "p".application_id = vr_application_id AND "p".post_id = ps.post_id
		INNER JOIN users_normal AS share_sender
		ON share_sender.application_id = vr_application_id AND share_sender.user_id = ps.sender_user_id
		INNER JOIN users_normal AS post_sender
		ON post_sender.application_id = vr_application_id AND post_sender.user_id = "p".sender_user_id
	WHERE ps.deleted = FALSE AND share_sender.is_approved = TRUE
	ORDER BY ps.score_date DESC;
END;
$$ LANGUAGE plpgsql;

