DROP FUNCTION IF EXISTS qa_check_nodes;

CREATE OR REPLACE FUNCTION qa_check_nodes
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[]
)
RETURNS TABLE (
	node_id		UUID,
	"count"		INTEGER,
	total_count	INTEGER,
	node_name	VARCHAR,
	node_type	VARCHAR,
	deleted		BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	x.node_id,
			x.questions_count AS "count",
			0::INTEGER AS total_count,
			nd.node_name,
			nd.type_name AS node_type,
			nd.deleted
	FROM (
			SELECT	ids.value AS node_id,
					COUNT(q.question_id)::INTEGER AS questions_count
			FROM UNNEST(vr_node_ids) AS ids
				LEFT JOIN qa_related_nodes AS r
				ON r.application_id = vr_application_id AND 
					r.node_id = ids.value AND r.deleted = FALSE
				LEFT JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = r.question_id AND 
					q.publication_date IS NOT NULL AND q.deleted = FALSE
			GROUP BY ids.value
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	ORDER BY x.questions_count DESC, x.node_id ASC;
END;
$$ LANGUAGE plpgsql;

