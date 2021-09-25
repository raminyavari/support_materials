DROP FUNCTION IF EXISTS cn_get_favorite_nodes;

CREATE OR REPLACE FUNCTION cn_get_favorite_nodes
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_ids	guid_table_type[],
	vr_node_id			UUID,
	vr_additional_id	VARCHAR(50),
	vr_search_text		VARCHAR(1000),
	vr_is_document		BOOLEAN,
	vr_lower_date_limit TIMESTAMP,
	vr_upper_date_limit TIMESTAMP,
	vr_lower_boundary 	INTEGER,
	vr_count		 	INTEGER
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_nt_count	INTEGER;
BEGIN
	vr_nt_count := COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0)::INTEGER;
	
	IF vr_node_id IS NOT NULL THEN 
		vr_nt_count := 0;
	END IF;
	
	IF vr_node_id IS NOT NULL OR vr_additional_id = '' THEN
		vr_additional_id = NULL;
	END IF;
	
	IF vr_count IS NULL OR vr_count <= 0 THEN
		vr_count = 10;
	END IF;
	
	vr_search_text := gfn_verify_string(vr_search_text);
	
	WITH "data" AS (
		SELECT 	ROW_NUMBER() OVER (
					ORDER BY 	pgroonga_score(nd.tableoid, nd.ctid) DESC, 
								nl.like_date DESC, 
								nl.node_id DESC
				) AS "row_number", 
				nl.node_id
		FROM cn_node_likes AS nl
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = nl.node_id AND (
					COALESCE(vr_search_text, '') = '' OR nd.name &@~ vr_search_text OR
					nd.additional_id &@~ vr_search_text
				)
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
		WHERE nl.application_id = vr_application_id AND nl.user_id = vr_user_id AND 
			(vr_node_id IS NULL OR nd.node_id = vr_node_id) AND
			(vr_nt_count = 0 OR nd.node_type_id IN (SELECT x.value FROM UNNEST(vr_node_type_ids) AS x)) AND 
			(vr_additional_id IS NULL OR nd.additional_id = vr_additional_id) AND
			(vr_is_document IS NULL OR COALESCE(s.is_document, FALSE) = vr_is_document) AND
			(vr_lower_date_limit IS NULL OR nd.creation_date >= vr_lower_date_limit) AND
			(vr_upper_date_limit IS NULL OR nd.creation_date < vr_upper_date_limit) AND
			nl.deleted = FALSE AND nd.deleted = FALSE
	)
	SELECT	vr_ret_ids = ARRAY(
				SELECT d.node_id
				FROM "data" AS d
				WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
				ORDER BY d.row_number ASC
				LIMIT vr_count
			),
			vr_total_count = COALESCE((
				SELECT COUNT(d.node_id) FROM "data" AS d
			), 0)::INTEGER;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_node_ids, FALSE, NULL, vr_total_count);
END;
$$ LANGUAGE plpgsql;
