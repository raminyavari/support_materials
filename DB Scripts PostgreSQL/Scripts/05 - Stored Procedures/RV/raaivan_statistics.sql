DROP FUNCTION IF EXISTS rv_raaivan_statistics;

CREATE OR REPLACE FUNCTION rv_raaivan_statistics
(
	vr_application_id	UUID,
	vr_date_from	 	TIMESTAMP,
	vr_date_to		 	TIMESTAMP
)
RETURNS TABLE (
	nodes_count				INTEGER,
	questions_count			INTEGER,
	answers_count			INTEGER,
	wiki_changes_count		INTEGER,
	posts_count				INTEGER,
	comments_count			INTEGER,
	active_users_count		INTEGER,
	node_page_visits_count	INTEGER,
	searches_count			INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 
		(
			SELECT COUNT(nd.node_id)::INTEGER
			FROM cn_view_nodes_normal AS nd
			WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE AND
				(vr_date_from IS NULL OR nd.creation_date >= vr_date_from) AND
				(vr_date_to IS NULL OR nd.creation_date <= vr_date_to)
		) AS nodes_count,
		(
			SELECT COUNT(q.question_id)::INTEGER
			FROM qa_questions AS q
			WHERE q.application_id = vr_application_id AND 
				q.publication_date IS NOT NULL AND q.deleted = FALSE AND
				(vr_date_from IS NULL OR q.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR q.send_date <= vr_date_to)
		) AS questions_count,
		(
			SELECT COUNT("a".answer_id)::INTEGER
			FROM qa_answers AS "a"
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = "a".question_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
			WHERE "a".application_id = vr_application_id AND "a".deleted = FALSE AND
				(vr_date_from IS NULL OR "a".send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR "a".send_date <= vr_date_to)
		) AS answers_count,
		(
			SELECT COUNT("c".change_id)::INTEGER
			FROM wk_changes AS "c"
			WHERE "c".application_id = vr_application_id AND 
				"c".applied = TRUE AND "c".deleted = FALSE AND
				(vr_date_from IS NULL OR "c".send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR "c".send_date <= vr_date_to)
		) AS wiki_changes_count,
		(
			SELECT COUNT(ps.share_id)::INTEGER
			FROM sh_post_shares AS ps
			WHERE ps.application_id = vr_application_id AND ps.deleted = FALSE AND
				(vr_date_from IS NULL OR ps.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR ps.send_date <= vr_date_to)
		) AS posts_count,
		(
			SELECT COUNT("c".comment_id)::INTEGER
			FROM sh_comments AS "c"
			WHERE "c".application_id = vr_application_id AND "c".deleted = FALSE AND
				(vr_date_from IS NULL OR "c".send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR "c".send_date <= vr_date_to)
		) AS comments_count,
		(
			SELECT COUNT(DISTINCT lg.user_id)::INTEGER
			FROM lg_logs AS lg
			WHERE lg.application_id = vr_application_id AND lg.action = 'Login' AND
				(vr_date_from IS NULL OR lg.date >= vr_date_from) AND
				(vr_date_to IS NULL OR lg.date <= vr_date_to)
		) AS active_users_count,
		(
			SELECT COUNT(iv.item_id)::INTEGER
			FROM cn_nodes AS nd
				INNER JOIN usr_item_visits AS iv
				ON iv.application_id = vr_application_id AND iv.item_id = nd.node_id
			WHERE nd.application_id = vr_application_id AND nd.node_id = iv.item_id AND nd.deleted = FALSE AND
				(vr_date_from IS NULL OR iv.visit_date >= vr_date_from) AND
				(vr_date_to IS NULL OR iv.visit_date <= vr_date_to)
		) AS node_page_visits_count,
		(
			SELECT COUNT(lg.log_id)::INTEGER
			FROM lg_logs AS lg
			WHERE lg.application_id = vr_application_id AND lg.action = 'Search' AND
				(vr_date_from IS NULL OR lg.date >= vr_date_from) AND
				(vr_date_to IS NULL OR lg.date <= vr_date_to)
		) AS searches_count;
END;
$$ LANGUAGE plpgsql;

