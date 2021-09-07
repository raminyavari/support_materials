DROP FUNCTION IF EXISTS cn_get_most_populated_node_types;

CREATE OR REPLACE FUNCTION cn_get_most_populated_node_types
(
	vr_application_id	UUID,
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	"order"					INTEGER,
	reverse_order			INTEGER,
	node_type_id			UUID,
	node_type_additional_id	VARCHAR,
	type_name				VARCHAR,
	nodes_count				BIGINT
)
AS
$$
BEGIN
	IF COALESCE(vr_count, 0) <= 0 THEN 
		vr_count := 10000;
	END IF;
	
	RETURN QUERY
	SELECT	rf.row_number::INTEGER,
			rf.rev_row_number::INTEGER,
			rf.node_type_id,
			rf.type_additional_id,
			rf.node_type,
			rf.count::BIGINT
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY x.count DESC, x.node_type_id DESC) AS "row_number",
					ROW_NUMBER() OVER (ORDER BY x.count ASC, x.node_type_id ASC) AS rev_row_number,
					x.*
			FROM (
					SELECT	node_type_id,
							MAX(nd.type_additional_id) AS type_additional_id,
							MAX(nd.type_name) AS node_type, 
							COUNT(nd.node_id) AS "count"
					FROM cn_view_nodes_normal AS nd
					WHERE nd.application_id = vr_application_id AND 
						nd.type_deleted = FALSE AND nd.deleted = FALSE
					GROUP BY nd.node_type_id
				) AS x
		) AS rf
	WHERE rf.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY rf.row_number ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;
