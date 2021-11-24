DROP FUNCTION IF EXISTS qa_get_related_questions;

CREATE OR REPLACE FUNCTION qa_get_related_questions
(
	vr_application_id		UUID,
    vr_user_id		 		UUID,
    vr_groups			 	BOOLEAN,
	vr_expertise_domains 	BOOLEAN,
	vr_favorites		 	BOOLEAN,
	vr_properties		 	BOOLEAN,
	vr_from_friends	 		BOOLEAN,
	vr_count			 	INTEGER,
	vr_lower_boundary		BIGINT
)
RETURNS TABLE (
	"row_number"		INTEGER,
	question_id			UUID,
	title				VARCHAR,
	send_date			TIMESTAMP,
	sender_user_id		UUID,
	has_best_answer		BOOLEAN,
	status				VARCHAR,
	related_nodes_count	INTEGER,
	is_group			BOOLEAN,
	is_expertise_domain	BOOLEAN,
	is_favorite			BOOLEAN,
	is_property			BOOLEAN,
	from_friend			BOOLEAN,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR,
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
		SELECT	ROW_NUMBER() OVER (ORDER BY MAX(qs.send_date) DESC, qs.question_id ASC)::INTEGER AS "row_number",
				qs.question_id,
				MAX(qs.title) AS title,
				MAX(qs.send_date) AS send_date,
				MAX(qs.sender_user_id::VARCHAR(50))::UUID AS sender_user_id,
				MAX(qs.has_best_answer::INTEGER)::BOOLEAN AS has_best_answer,
				MAX(qs.status) AS status,
				COUNT(qs.related_node_id) AS related_nodes_count,
				MAX(qs.is_group::INTEGER)::BOOLEAN AS is_group,
				MAX(qs.is_expertise::INTEGER)::BOOLEAN AS is_expertise_domain,
				MAX(qs.is_favorite::INTEGER)::BOOLEAN AS is_favorite,
				MAX(qs.is_property::INTEGER)::BOOLEAN AS is_property,
				MAX(qs.from_friend::INTEGER)::BOOLEAN AS from_friend
		FROM (
				SELECT	q.question_id, 
						q.title,
						q.send_date,
						q.sender_user_id,
						CASE WHEN q.best_answer_id IS NULL THEN FALSE ELSE TRUE END::INTEGER AS has_best_answer,
						q.status,
						nodes.node_id AS related_node_id,
						nodes.is_group,
						nodes.is_expertise,
						nodes.is_favorite,
						nodes.is_property,
						FALSE AS from_friend
				FROM (
						SELECT	x.node_id, 
								MAX(x.is_group) AS is_group, 
								MAX(x.is_expertise) AS is_expertise, 
								MAX(x.is_favorite) AS is_favorite, 
								MAX(x.is_property) AS is_property
						FROM (
								SELECT 	nm.node_id, 
										TRUE AS is_group, 
										FALSE AS is_expertise, 
										FALSE AS is_favorite, 
										FALSE AS is_property
								FROM cn_view_node_members AS nm
								WHERE vr_groups = TRUE AND nm.application_id = vr_application_id AND 
									nm.user_id = vr_user_id AND COALESCE(nm.is_pending, FALSE) = FALSE

								UNION ALL

								SELECT 	x.node_id, 
										FALSE AS is_group, 
										TRUE AS is_expertise, 
										FALSE AS is_favorite, 
										FALSE AS is_property
								FROM cn_view_experts AS x
								WHERE vr_expertise_domains = TRUE AND 
									x.application_id = vr_application_id AND x.user_id = vr_user_id

								UNION ALL

								SELECT 	nl.node_id, 
										FALSE AS is_group, 
										FALSE AS is_expertise, 
										TRUE AS is_favorite, 
										FALSE AS is_property
								FROM cn_node_likes AS nl
									INNER JOIN cn_nodes AS nd
									ON nd.application_id = vr_application_id AND 
										nd.node_id = nl.node_id AND nd.deleted = FALSE
								WHERE vr_favorites = TRUE AND nl.application_id = vr_application_id AND 
									nl.user_id = vr_user_id AND nl.deleted = FALSE

								UNION ALL

								SELECT 	nc.node_id, 
										FALSE AS is_group, 
										FALSE AS is_expertise, 
										FALSE AS is_favorite, 
										TRUE AS is_property
								FROM cn_node_creators AS nc
									INNER JOIN cn_nodes AS nd
									ON nd.application_id = vr_application_id AND 
										nd.node_id = nc.node_id AND nd.deleted = FALSE
								WHERE vr_properties = TRUE AND nc.application_id = vr_application_id AND 
									nc.user_id = vr_user_id AND nc.deleted = FALSE
							) AS x
						GROUP BY x.node_id
					) AS nodes
					INNER JOIN qa_related_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = nodes.node_id
					INNER JOIN qa_questions AS q
					ON q.application_id = vr_application_id AND q.question_id = nd.question_id AND 
						q.publication_date IS NOT NULL AND q.deleted = FALSE
				WHERE nd.deleted = FALSE

				UNION ALL

				SELECT	q.question_id, 
						q.title,
						q.send_date, 
						q.sender_user_id,
						CASE WHEN q.best_answer_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN AS has_best_answer,
						q.status,
						NULL AS related_node_id,
						FALSE AS is_group,
						FALSE AS is_expertise,
						FALSE AS is_favorite,
						FALSE AS is_property,
						TRUE AS from_friend
				FROM qa_questions AS q
					INNER JOIN usr_view_friends AS f
					ON f.application_id = vr_application_id AND f.user_id = vr_user_id AND 
						f.friend_id = q.sender_user_id AND f.are_friends = TRUE
				WHERE vr_from_friends = TRUE AND q.publication_date IS NOT NULL AND q.deleted = FALSE
			) AS qs
		GROUP BY qs.question_id
	),
	total AS
	(
		SELECT COUNT(d.question_id) AS total_count
		FROM "data" AS d
	)
	SELECT 	questions.*,
			un.username AS sender_username,
			un.first_name AS sender_first_name,
			un.last_name AS sender_last_name,
			(
				SELECT COUNT("a".answer_id)
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
			"t".total_count::INTEGER AS total_count
	FROM "data" AS questions
		CROSS JOIN total AS "t"
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = questions.sender_user_id
	WHERE questions.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY questions.row_number ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

