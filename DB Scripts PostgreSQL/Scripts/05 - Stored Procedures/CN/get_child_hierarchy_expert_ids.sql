DROP FUNCTION IF EXISTS cn_get_child_hierarchy_expert_ids;

CREATE OR REPLACE FUNCTION cn_get_child_hierarchy_expert_ids
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_search_text	 	VARCHAR(255),
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	user_id		UUID,
	total_count	INTEGER
)
AS
$$
DECLARE
	vr_ids		UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT vr_node_id
		WHERE vr_node_id IS NOT NULL
	);
	
	IF COALESCE(vr_count, 0) <= 0 THEN
		vr_count = 1000000;
	END IF;
	
	RETURN QUERY
	WITH ids AS (
		SELECT DISTINCT rf.node_id
		FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_ids) AS rf
	),
	"data" AS (
		SELECT	ROW_NUMBER() OVER (ORDER BY u.user_id ASC) AS "row_number",
				u.user_id
		FROM (
				SELECT DISTINCT ex.user_id
				FROM ids AS x
					INNER JOIN cn_view_experts AS ex
					ON ex.node_id = x.node_id
				WHERE ex.application_id = vr_application_id
			) AS u
			INNER JOIN usr_profile AS "p"
			ON "p".application_id = vr_application_id AND 
				"p".user_id = u.user_id AND "p".is_approved = TRUE AND (
					COALESCE(vr_search_text, '')::VARCHAR = ''::VARCHAR OR "p".username &@~ vr_search_text OR 
					"p".first_name &@~ vr_search_text OR "p".last_name &@~ vr_search_text
				)
	),
	total AS (
		SELECT COUNT(d.user_id) AS total_count
		FROM "data" AS d
	)
	SELECT 	d.user_id, 
			total.total_count::INTEGER
	FROM "data" AS d
		CROSS JOIN total
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;
