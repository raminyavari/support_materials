DROP FUNCTION IF EXISTS qa_group_questions_by_related_nodes;

CREATE OR REPLACE FUNCTION qa_group_questions_by_related_nodes
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_question_id		UUID,
	vr_search_text	 	VARCHAR(1000),
	vr_default_privacy	VARCHAR(50),
	vr_check_access 	BOOLEAN,
	vr_now		 		TIMESTAMP,
	vr_count		 	INTEGER,
	vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	node_id			UUID,
	node_name		VARCHAR,
	node_type		VARCHAR,
	deleted			BOOLEAN,
	"count"			INTEGER,
	"row_number"	INTEGER,
	total_count		INTEGER
)
AS
$$
DECLARE
	vr_permission_types	string_pair_table_type[];
BEGIN
	vr_permission_types := ARRAY(
		SELECT ROW('View', vr_default_privacy)
	);

	RETURN QUERY
	WITH "data" AS
	(
		SELECT 	n.node_id, 
				COUNT(q.question_id)::INTEGER AS "count"
		FROM qa_related_nodes AS n
			INNER JOIN qa_questions AS q
			ON q.application_id = vr_application_id AND q.question_id = n.question_id AND 
				q.publication_date IS NOT NULL AND q.deleted = FALSE
		WHERE n.application_id = vr_application_id AND n.deleted = FALSE
		GROUP BY n.node_id
	),
	new_data AS
	(
		SELECT *
		FROM "data" AS d
		WHERE vr_question_id IS NULL OR d.node_id IN (
				SELECT r.node_id
				FROM qa_related_nodes AS r
				WHERE r.application_id = vr_application_id AND 
						r.question_id = vr_question_id AND r.deleted = FALSE
			)
	),
	filtered AS
	(
		SELECT d.*
		FROM new_data AS d
			LEFT JOIN prvc_fn_check_access(vr_application_id, vr_current_user_id, 
										   ARRAY(
											   SELECT y.node_id
											   FROM new_data AS y
										   ), 
										   'FAQCategory', vr_now, vr_permission_types) AS x
			ON x.id = d.node_id
		WHERE COALESCE(vr_check_access, FALSE)::BOOLEAN = FALSE OR x.id IS NOT NULL
	),
	total AS
	(
		SELECT COUNT(f.node_id)::INTEGER AS total_count
		FROM filtered AS f
	)
	SELECT 	x.node_id,
			nd.node_name,
			nd.type_name AS node_type,
			nd.deleted,
			x.count,
			x.row_number,
			"t".total_count AS total_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY 
									   pgroonga_score(n.tableoid, n.ctid) DESC, 
									   f.count DESC, 
									   f.node_id ASC)::INTEGER AS "row_number",
					f.node_id,
					f.count
			FROM filtered AS f
				INNER JOIN cn_nodes AS n
				ON n.application_id = vr_application_id AND n.node_id = f.node_id AND
					(COALESCE(vr_search_text, '') = '' OR n.name &@~ vr_search_text OR
						n.additional_id &@~ vr_search_text)
		) AS x
		CROSS JOIN total AS "t"
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
	LIMIT COALESCE(vr_count, 1000000);
END;
$$ LANGUAGE plpgsql;

