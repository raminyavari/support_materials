DROP FUNCTION IF EXISTS rv_get_last_content_creators;

CREATE OR REPLACE FUNCTION rv_get_last_content_creators
(
	vr_application_id	UUID,
	vr_count			INTEGER
)
RETURNS TABLE (
	user_id		UUID,
	username	VARCHAR,
	first_name	VARCHAR,
	last_name	VARCHAR,
	date		TIMESTAMP,
	"types"		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	WITH users AS 
	(
		SELECT	x.user_id, 
				MAX(x.date) AS date,
				'Post' AS "type"
		FROM (
				SELECT ps.sender_user_id AS user_id, ps.send_date AS date
				FROM sh_post_shares AS ps
				WHERE ps.application_id = vr_application_id AND ps.deleted = FALSE
				ORDER BY ps.send_date DESC
				LIMIT 20
			) AS x
		GROUP BY x.user_id

		UNION ALL

		SELECT	x.user_id, 
				MAX(x.date) AS date,
				'Question' AS "type"
		FROM (
				SELECT q.sender_user_id AS user_id, q.send_date AS date
				FROM qa_questions AS q
				WHERE q.application_id = vr_application_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
				ORDER BY q.send_date DESC
				LIMIT 20
			) AS x
		GROUP BY x.user_id

		UNION ALL

		SELECT	x.user_id, 
				MAX(x.date) AS date,
				'Node' AS "type"
		FROM (
				SELECT nd.creator_user_id AS user_id, nd.creation_date AS date
				FROM cn_nodes AS nd
				WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE
				ORDER BY nd.creation_date DESC
				LIMIT 20
			) AS x
		GROUP BY x.user_id

		UNION ALL

		SELECT	x.user_id, 
				MAX(x.date) AS date,
				'Wiki' AS "type"
		FROM (
				SELECT "c".user_id AS user_id, "c".send_date  AS date
				FROM wk_changes AS "c"
				WHERE "c".application_id = vr_application_id AND "c".applied = TRUE
				ORDER BY "c".send_date DESC
				LIMIT 20
			) AS x
		GROUP BY x.user_id
	)
	SELECT 	x.user_id,
			un.username,
			un.first_name,
			un.last_name,
			x.date,
			x.types
	FROM (
			SELECT	u.user_id, 
					MAX(u.date) AS date,
					STRING_AGG(u.type, ',') AS "types"
			FROM users AS u
			GROUP BY u.user_id
		) AS x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.user_id
	ORDER BY x.date DESC
	LIMIT COALESCE(vr_count, 10);
END;
$$ LANGUAGE plpgsql;

