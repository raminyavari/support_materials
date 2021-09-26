DROP FUNCTION IF EXISTS cn_get_experts;

CREATE OR REPLACE FUNCTION cn_get_experts
(
	vr_application_id	UUID,
    vr_node_ids			guid_table_type[],
	vr_search_text	 	VARCHAR(255),
	vr_hierarchy	 	BOOLEAN,
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	"order"				INTEGER,
	total_count			INTEGER,
	node_id				UUID,
	expert_user_id		UUID,
	node_additional_id	VARCHAR,
	node_name			VARCHAR,
	node_type_id		UUID,
	node_type			VARCHAR,
	expert_username		VARCHAR,
	expert_first_name	VARCHAR,
	expert_last_name	VARCHAR
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_node_ids) AS x
	);

	IF vr_hierarchy = TRUE THEN
		vr_ids := ARRAY(
			SELECT UNNEST(vr_ids)
			
			UNION
			
			SELECT DISTINCT "t".node_id
			FROM cn_fn_get_nodes_hierarchy(vr_application_id, vr_ids) AS "t"
				LEFT JOIN UNNEST(vr_ids) AS x
				ON x = "t".node_id
			WHERE x IS NULL
		);
	END IF;
	
	IF COALESCE(vr_count, 0) <= 0 THEN
		vr_count := 1000000;
	END IF;
	
	RETURN QUERY
	WITH "data" AS (
		SELECT	ROW_NUMBER() OVER (
					ORDER BY 	pgroonga_score("p".tableoid, "p".ctid) DESC,
								ex.node_id DESC, 
								ex.user_id DESC
				) AS "row_number",
				ex.node_id,
				ex.user_id,
				"p".username,
				"p".first_name,
				"p".last_name
		FROM UNNEST(vr_ids) AS n
			INNER JOIN cn_view_experts AS ex
			ON ex.application_id = vr_application_id AND ex.node_id = n
			INNER JOIN usr_profile AS "p"
			ON "p".application_id = vr_application_id AND "p".user_id = ex.user_id AND (
					COALESCE(vr_search_text, '') = '' OR "p".username &@~ vr_search_text OR
					"p".first_name &@~ vr_search_text OR "p".last_name &@~ vr_search_text
				)
	),
	total AS (
		SELECT COUNT(d.node_id) AS total_count
		FROM "data" AS d
	)
	SELECT	rf.row_number::INTEGER AS "order",
			"t".total_count::INTEGER,
			rf.node_id,
			rf.user_id AS expert_user_id,
			nd.node_additional_id AS node_additional_id,
			nd.node_name AS node_name,
			nd.node_type_id AS node_type_id,
			nd.type_name AS node_type,
			rf.username AS expert_username,
			rf.first_name AS expert_first_name,
			rf.last_name AS expert_last_name
	FROM "data" AS rf
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rf.node_id
		CROSS JOIN total AS "t"
	WHERE rf.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY rf.row_number ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;
