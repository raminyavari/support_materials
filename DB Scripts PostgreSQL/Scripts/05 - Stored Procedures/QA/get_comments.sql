DROP FUNCTION IF EXISTS qa_get_comments;

CREATE OR REPLACE FUNCTION qa_get_comments
(
	vr_application_id		UUID,
	vr_question_id	 		UUID,
    vr_current_user_id		UUID
)
RETURNS TABLE (
	comment_id			UUID,
	owner_id			UUID,
	reply_to_comment_id	UUID,
	body_text			VARCHAR,
	sender_user_id		UUID,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR,
	send_date			TIMESTAMP,
	likes_count			INTEGER,
	like_status			BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM (
			SELECT	"c".comment_id,
					"c".owner_id,
					"c".reply_to_comment_id,
					"c".body_text,
					"c".sender_user_id,
					un.username AS sender_username,
					un.first_name AS sender_first_name,
					un.last_name AS sender_last_name,
					"c".send_date,
					(
						SELECT COUNT(l.user_id)
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.liked_id = c.comment_id AND l.like = TRUE
					)::INTEGER AS likes_count,
					(
						SELECT l.like
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.user_id = vr_current_user_id AND l.liked_id = "c".comment_id
						LIMIT 1
					)::BOOLEAN AS like_status
			FROM qa_comments AS "c"
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = "c".sender_user_id
			WHERE "c".application_id = vr_application_id AND "c".owner_id = vr_question_id AND "c".deleted = FALSE
			
			UNION ALL
			
			SELECT	"c".comment_id,
					"c".owner_id,
					"c".reply_to_comment_id,
					"c".body_text,
					"c".sender_user_id,
					un.username AS sender_username,
					un.first_name AS sender_first_name,
					un.last_name AS sender_last_name,
					"c".send_date,
					(
						SELECT COUNT(l.user_id)
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.liked_id = c.comment_id AND l.like = TRUE
					)::INTEGER AS likes_count,
					(
						SELECT l.like
						FROM rv_likes AS l
						WHERE l.application_id = vr_application_id AND 
							l.user_id = vr_current_user_id AND l.liked_id = c.comment_id
						LIMIT 1
					)::BOOLEAN AS like_status
			FROM qa_answers AS "a"
				INNER JOIN qa_comments AS "c"
				ON "c".application_id = vr_application_id AND 
					"c".owner_id = "a".answer_id AND "c".deleted = FALSE
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = "c".sender_user_id
			WHERE "a".application_id = vr_application_id AND 
				"a".question_id = vr_question_id AND "a".deleted = FALSE
		) AS x
	ORDER BY x.send_date ASC, x.comment_id ASC;
END;
$$ LANGUAGE plpgsql;

