DROP FUNCTION IF EXISTS qa_find_knowledgeable_user_ids;

CREATE OR REPLACE FUNCTION qa_find_knowledgeable_user_ids
(
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_count		 	INTEGER,
	vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	"id"		UUID,
	total_count	INTEGER
)
AS
$$
DECLARE
	vr_sender_user_id	UUID;
BEGIN
	SELECT vr_sender_user_id = q.sender_user_id
	FROM qa_questions AS q
	WHERE q.application_id = vr_application_id AND q.question_id = vr_question_id
	LIMIT 1;
	
	RETURN QUERY
	WITH questions
 	AS 
	(
		SELECT	r2.question_id, 
				COUNT(DISTINCT r2.node_id) AS common_tags_count
		FROM qa_related_nodes AS r
			INNER JOIN qa_related_nodes AS r2
			ON r2.application_id = vr_application_id AND 
				r2.question_id <> vr_question_id AND r2.node_id = r.node_id AND r2.deleted = FALSE
		WHERE r.application_id = vr_application_id AND 
			r.question_id = vr_question_id AND r.deleted = FALSE
		GROUP BY r2.question_id
	),
	"data" AS
	(
		SELECT	scores.user_id, 
				SUM(scores.score) AS score, 
				SUM(scores.tag_score) AS tag_score, 
				SUM(scores.best_answer_score) AS best_answer_score,
				SUM(scores.likes_score) AS like_score
		FROM (
				SELECT	"found".question_id,
						"found".user_id,
						(
							(2 * "found".common_tags_count::FLOAT / max_tags.count::FLOAT) + 
							(1.5 * "found".is_best_answer_sender::FLOAT) +
							(
								"found".likes_count::FLOAT / 
								CASE WHEN COALESCE(max_likes.count, 0) = 0 THEN 1 ELSE max_likes.count END::FLOAT
							)
						) AS score,
						("found".common_tags_count::FLOAT / max_tags.count::FLOAT) AS tag_score,
						"found".is_best_answer_sender::FLOAT AS best_answer_score,
						(
							"found".likes_count::FLOAT / 
							CASE WHEN COALESCE(max_likes.count, 0) = 0 THEN 1 ELSE max_likes.count END::FLOAT
						) AS likes_score
				FROM (
						SELECT	qux.question_id,
								qux.user_id,
								MAX(qux.common_tags_count) AS common_tags_count,
								MAX(qux.is_best_answer_sender) AS is_best_answer_sender,
								MAX(qux.likes_count) AS likes_count
						FROM (
							SELECT	"a".question_id, 
									qu.common_tags_count,
									"a".sender_user_id AS user_id, 
									1::INTEGER is_best_answer_sender,
									0::INTEGER AS likes_count
							FROM questions AS qu
								INNER JOIN qa_questions AS q
								ON q.application_id = vr_application_id AND 
									q.question_id = qu.question_id AND q.best_answer_id IS NOT NULL
								INNER JOIN qa_answers AS "a"
								ON "a".application_id = vr_application_id AND "a".answer_id = q.best_answer_id

							UNION ALL

							SELECT	x.question_id, 
									MAX(x.common_tags_count) AS common_tags_count,
									x.sender_user_id AS user_id, 
									0::INTEGER is_best_answer_sender,
									MAX(x.likes_count) AS likes_count
							FROM (
									SELECT	"a".question_id, 
											MAX(qu.common_tags_count) AS common_tags_count,
											"a".sender_user_id, 
											SUM(
												CASE 
													WHEN l.like IS NULL THEN 0
													WHEN l.like = FALSE THEN -1
													ELSE 1
												END::INTEGER
											) AS likes_count
									FROM questions AS qu
										INNER JOIN qa_answers AS "a"
										ON "a".application_id = vr_application_id AND 
											"a".question_id = qu.question_id AND "a".deleted = FALSE
										LEFT JOIN rv_likes AS l
										ON l.application_id = vr_application_id AND l.liked_id = "a".answer_id
									GROUP BY "a".question_id, "a".answer_id, "a".sender_user_id
								) AS x
							WHERE x.likes_count >= 0
							GROUP BY x.question_id, x.sender_user_id
						) AS qux
						GROUP BY qux.question_id, qux.user_id
					) AS "found"
					CROSS JOIN (
						SELECT MAX(qu.common_tags_count) AS "count"
						FROM questions AS qu
					) AS max_tags
					LEFT JOIN (
						SELECT	x.question_id, 
								MAX(x.likes_count) AS "count"
						FROM (
								SELECT	"a".question_id, 
										SUM(
											CASE 
												WHEN l.like IS NULL THEN 0
												WHEN l.like = FALSE THEN -1
												ELSE 1
											END::INTEGER
										) AS likes_count
								FROM questions AS qu
									INNER JOIN qa_answers AS "a"
									ON "a".application_id = vr_application_id AND 
										"a".question_id = qu.question_id AND "a".deleted = FALSE
									LEFT JOIN rv_likes AS l
									ON l.application_id = vr_application_id AND l.liked_id = "a".answer_id
								GROUP BY "a".question_id, "a".answer_id, "a".sender_user_id
							) AS x
						WHERE x.likes_count >= 0
						GROUP BY x.question_id
					) AS max_likes
					ON max_likes.question_id = "found".question_id
			) AS scores
		GROUP BY scores.user_id
	),
	new_data AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY u.score DESC, u.user_id ASC) AS "row_number",
				u.*
		FROM "data" AS d
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND 
				un.user_id = d.user_id AND un.is_approved = TRUE
		WHERE d.user_id <> vr_sender_user_id
	),
	total AS
	(
		SELECT COUNT(d.user_id)::INTEGER AS total_count
		FROM new_data AS d
	)
	SELECT	x.user_id AS "id",
			"t".total_count
	FROM new_data AS x
		CROSS JOIN total AS "t"
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

