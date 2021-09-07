DROP FUNCTION IF EXISTS sh_p_get_comments_by_ids;

CREATE OR REPLACE FUNCTION sh_p_get_comments_by_ids
(
	vr_application_id	UUID,
    vr_comment_ids		UUID[],
    vr_user_id			UUID
)
RETURNS SETOF sh_comment_ret_composite
AS
$$
BEGIN
	RETURN QUERY
    SELECT "c".comment_id,
		   "c".share_id AS post_id,
		   "c".description,
		   "c".sender_user_id,
		   "c".send_date,
		   un.first_name,
		   un.lastname,
		   (
				SELECT COUNT(*) 
				FROM sh_comment_likes AS cl
				WHERE cl.application_id = vr_application_id AND 
					cl.comment_id = c.comment_id AND cl.like = TRUE
			) AS likes_count,
			(
				SELECT COUNT(*) 
				FROM sh_comment_likes AS cl
				WHERE cl.application_id = vr_application_id AND 
					cl.comment_id = c.comment_id AND cl.like = FALSE
			) AS dislikes_count,
			(
				SELECT cl.like 
				FROM sh_comment_likes AS cl
				WHERE cl.application_id = vr_application_id AND cl.comment_id = 
					c.comment_id AND cl.user_id = vr_user_id
			) AS like_status
	FROM UNNEST(vr_comment_ids) AS ex_id
		INNER JOIN sh_comments AS "c"
		ON "c".application_id = vr_application_id AND "c".comment_id = ex_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = c.sender_user_id
	ORDER BY "c".send_date;
END;
$$ LANGUAGE plpgsql;

