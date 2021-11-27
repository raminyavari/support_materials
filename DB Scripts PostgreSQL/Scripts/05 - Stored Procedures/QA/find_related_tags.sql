DROP FUNCTION IF EXISTS qa_find_related_tags;

CREATE OR REPLACE FUNCTION qa_find_related_tags
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_count		 	INTEGER,
	vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	node_id		UUID,
	"count"		INTEGER,
	node_name	VARCHAR,
	node_type	VARCHAR,
	deleted		BOOLEAN,
	total_count	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY 
								   MAX(ids.count) DESC, 
								   COUNT(q.question_id) DESC, 
								   ids.node_id ASC)::INTEGER AS "row_number",
				ids.node_id,
				MAX(ids.count) AS "count",
				COUNT(q.question_id) AS questions_count
		FROM (
				SELECT 	r2.node_id, 
						COUNT(r2.question_id)::INTEGER AS "count"
				FROM qa_related_nodes AS r
					INNER JOIN qa_related_nodes AS r2
					ON r2.application_id = vr_application_id AND 
						r2.question_id = r.question_id AND r2.deleted = FALSE
				WHERE r.application_id = vr_application_id AND 
					r.node_id = vr_node_id AND r.deleted = FALSE
				GROUP BY r2.node_id
			) AS ids
			INNER JOIN qa_related_nodes AS r
			ON r.application_id = vr_application_id AND 
				r.node_id = ids.node_id AND r.deleted = FALSE
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
				q.publication_date IS NOT NULL AND q.deleted = FALSE
		GROUP BY ids.node_id
	),
	total AS
	(
		SELECT COUNT(d.node_id)::INTEGER AS total_count
		FROM "data" AS d
	)
	SELECT	x.node_id,
			x.questions_count AS "count",
			nd.node_name,
			nd.type_name AS node_type,
			nd.deleted,
			"t".total_count
	FROM "data" AS x
		CROSS JOIN total AS "t"
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

