DROP FUNCTION IF EXISTS qa_get_questions;

CREATE OR REPLACE FUNCTION qa_get_questions
(
	vr_application_id	UUID,
    vr_search_text	 	VARCHAR(1000),
	vr_date_from	 	TIMESTAMP,
	vr_date_to		 	TIMESTAMP,
	vr_count		 	INTEGER,
	vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	"row_number"		INTEGER,
	question_id			UUID, 
	title				VARCHAR, 
	send_date			TIMESTAMP, 
	sender_user_id		UUID,
	has_best_answer		BOOLEAN,
	status				VARCHAR,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR,
	related_nodes_count	INTEGER,
	answers_count		INTEGER,
	likes_count			INTEGER,
	dislikes_count		INTEGER,
	total_count			INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS 
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY 
								   pgroonga_score(q.tableoid, q.ctid) DESC, 
								   q.send_date DESC, 
								   q.question_id ASC) AS "row_number",
				q.question_id, 
				q.title, 
				q.send_date, 
				q.sender_user_id,
				CASE WHEN q.best_answer_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN AS has_best_answer,
				q.status
		FROM qa_questions AS q
		WHERE q.application_id = vr_application_id AND q.deleted = FALSE AND
			q.publication_date IS NOT NULL AND
			(COALESCE(vr_search_text, '') = '' OR q.title &@~ vr_search_text OR
				q.description &@~ vr_search_text) AND
			(vr_date_from IS NULL OR q.send_date >= vr_date_from) AND
			(vr_date_to IS NULL OR q.send_date < vr_date_to)
	),
	total AS
	(
		SELECT COUNT(d.question_id) AS total_count
		FROM "data" AS d
	)
	SELECT	questions.*,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			(
				SELECT COUNT(r.node_id)
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
					r.question_id = questions.question_id AND r.deleted = FALSE
			)::INTEGER AS related_nodes_count,
			(
				SELECT COUNT(a.answer_id)
				FROM qa_answers AS "a"
				WHERE "a".application_id = vr_application_id AND 
					"a".question_id = questions.question_id AND "a".deleted = FALSE
			)::INTEGER AS answers_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = TRUE
			)::INTEGER AS likes_count,
			(
				SELECT COUNT(l.user_id)
				FROM rv_likes AS l
				WHERE l.application_id = vr_application_id AND 
					l.liked_id = questions.question_id AND l.like = FALSE
			)::INTEGER AS dislikes_count,
			total.total_count::INTEGER AS total_count
	FROM "data" AS questions
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

