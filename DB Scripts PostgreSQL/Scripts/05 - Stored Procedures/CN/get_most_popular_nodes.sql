DROP FUNCTION IF EXISTS cn_get_most_popular_nodes;

CREATE OR REPLACE FUNCTION cn_get_most_popular_nodes
(
	vr_application_id	UUID,
	vr_node_type_ids	guid_table_type[],
	vr_parent_node_id	UUID,
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	node_id 		UUID,
	node_type_id	UUID,
	"name"			VARCHAR,
	node_type		VARCHAR,
	visits_count	INTEGER,
	likes_count		INTEGER,
	"order"			INTEGER,
	total_count		BIGINT
)
AS
$$
DECLARE
	vr_cnt	INTEGER;
BEGIN
	vr_cnt := COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0)::INTEGER;

	RETURN QUERY
	SELECT 	rf.node_id,
			rf.node_type_id,
			rf.name,
			rf.node_type,
			rf.visits_count::INTEGER,
			rf.likes_count::INTEGER,
			rf.row_number::INTEGER AS "order",
			(rf.row_number + rf.rev_row_number - 1)::BIGINT AS total_count
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY (n.visits_count + n.likes_count) DESC, n.node_id DESC) AS "row_number",
					ROW_NUMBER() OVER (ORDER BY (n.visits_count + n.likes_count) ASC, n.node_id ASC) AS rev_row_number,
					n.*
			FROM (
					SELECT	v.node_id,
							v.node_type_id,
							v.name,
							v.node_type,
							v.count AS visits_count,
							COALESCE(l.count, 0) AS likes_count
					FROM (
							SELECT	nd.node_id,
									MAX(nd.node_type_id::VARCHAR(50))::UUID AS node_type_id,
									MAX(nd.node_name) AS "name",
									MAX(nd.type_name) AS node_type,
									COUNT(iv.user_id) AS "count"
							FROM cn_view_nodes_normal AS nd
								INNER JOIN usr_item_visits AS iv
								ON iv.application_id = vr_application_id AND iv.item_id = nd.node_id
							WHERE nd.application_id = vr_application_id AND 
								(vr_cnt = 0 OR nd.node_type_id IN (SELECT x.value FROM UNNEST(vr_node_type_ids) AS x)) AND
								(vr_parent_node_id IS NULL OR nd.parent_node_id = vr_parent_node_id) AND
								nd.deleted = FALSE
							GROUP BY nd.node_id
						) AS v
						LEFT JOIN (
							SELECT nl.node_id, COUNT(nl.user_id) AS "count"
							FROM cn_node_likes AS nl
							WHERE nl.application_id = vr_application_id
							GROUP BY nl.node_id
						) AS l
						ON l.node_id = v.node_id
				) AS n
		) AS rf
	WHERE rf.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY rf.row_number ASC
	LIMIT COALESCE(vr_count, 100)::INTEGER;
END;
$$ LANGUAGE plpgsql;
