DROP FUNCTION IF EXISTS qa_p_get_questions_by_ids;

CREATE OR REPLACE FUNCTION qa_p_get_questions_by_ids
(
	vr_application_id	UUID,
    vr_question_ids		UUID[],
    vr_current_user_id	UUID,
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF qa_question_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT	q.question_id,
			q.workflow_id,
			q.title,
			q.description,
			q.send_date,
			q.best_answer_id,
			q.sender_user_id,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			q.status,
			q.publication_date,
			(
				SELECT COUNT("a".answer_id)
				FROM qa_answers AS "a"
				WHERE "a".application_id = vr_application_id AND 
					"a".question_id = q.question_id AND "a".deleted = FALSE
			)::INTEGER AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = q.question_id AND l.like = TRUE
			)::INTEGER AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = q.question_id AND l.like = FALSE
			)::INTEGER AS dislikes_count,
			COALESCE((
				SELECT l.like
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = q.question_id AND l.user_id = vr_current_user_id
				LIMIT 1
			), FALSE)::BOOLEAN AS like_status,
			COALESCE((
				SELECT TRUE
				FROM rv_followers AS f
				WHERE f.application_id = vr_application_id AND 
					f.followed_id = q.question_id AND f.user_id = vr_current_user_id
				LIMIT 1
			), FALSE)::BOOLEAN AS follow_status,
			vr_total_count
	FROM UNNEST(vr_question_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = x.id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = q.sender_user_id
	ORDER BY x.seq ASC;
END;
$$ LANGUAGE plpgsql;

