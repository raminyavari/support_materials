DROP FUNCTION IF EXISTS qa_search_nodes;

CREATE OR REPLACE FUNCTION qa_search_nodes
(
	vr_application_id	UUID,
	vr_search_text	 	VARCHAR(500),
    vr_exact_search 	BOOLEAN,
    vr_order_by_rank 	BOOLEAN,
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
								  CASE
									WHEN vr_order_by_rank = TRUE THEN MAX(pgroonga_score(nd.tableoid, nd.ctid))::FLOAT
									ELSE COUNT(q.question_id)::FLOAT
								  END DESC,
								  COUNT(q.question_id) DESC,
								  nd.node_id ASC)::INTEGER AS "row_number",
				nd.node_id,
				COUNT(q.question_id)::INTEGER AS "count",
				MAX(nd.name) AS node_name,
				MAX(nt.name) AS node_type,
				MAX(nd.deleted::INTEGER)::BOOLEAN AS deleted
		FROM cn_nodes AS nd
			INNER JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND nt.node_type_id = nd.node_tpe_id
			LEFT JOIN qa_related_nodes AS r
			ON r.application_id = vr_application_id AND r.node_id = nd.node_id AND r.deleted = FALSE
			LEFT JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
				q.publication_date IS NOT NULL AND q.deleted = FALSE
		WHERE nd.application_id = vr_application_id AND COALESCE(vr_search_text, '') <> '' AND 
			LEN(nd.name) < 25 AND (
				(COALESCE(vr_exact_search, FALSE)::BOOLEAN = FALSE AND nd.name &@~ vr_search_text) OR
				(vr_exact_search = TRUE AND nd.name = vr_search_text)
			 )
		GROUP BY nd.node_id
	),
	total AS
	(
		SELECT COUNT(d.node_id)::INTEGER AS total_count
		FROM "data" AS d
	)
	SELECT 	x.node_id,
			x.count,
			x.node_name,
			x.node_type,
			x.deleted,
			"t".total_count
	FROM "data" AS d
		CROSS JOIN total AS "t"
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

