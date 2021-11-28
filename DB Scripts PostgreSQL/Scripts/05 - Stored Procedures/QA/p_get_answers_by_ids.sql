DROP FUNCTION IF EXISTS qa_p_get_answers_by_ids;

CREATE OR REPLACE FUNCTION qa_p_get_answers_by_ids
(
	vr_application_id	UUID,
	vr_answer_ids 		UUID[],
	vr_current_user_id	UUID,
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF qa_answer_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT	"a".answer_id,
			"a".question_id,
			"a".answer_body,
			"a".sender_user_id,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			"a".send_date,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = a.answer_id AND l.like = TRUE
			)::INTEGER AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = a.answer_id AND l.like = FALSE
			)::INTEGER AS dislikes_count,
			(
				SELECT l.like
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.user_id = vr_current_user_id AND l.liked_id = a.answer_id
				LIMIT 1
			)::BOOLEAN AS like_status,
			vr_total_count
	FROM UNNEST(vr_answer_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN qa_answers AS "a"
		ON "a".application_id = vr_application_id AND "a".answer_id = x.id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = "a".sender_user_id
	ORDER BY x.seq ASC;
END;
$$ LANGUAGE plpgsql;

