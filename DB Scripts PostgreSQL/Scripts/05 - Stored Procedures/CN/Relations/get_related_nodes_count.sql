DROP FUNCTION IF EXISTS cn_get_related_nodes_count;

CREATE OR REPLACE FUNCTION cn_get_related_nodes_count
(
	vr_application_id		UUID,
	vr_node_id				UUID,
	vr_related_node_type_id	UUID,
	vr_search_text		 	VARCHAR(1000),
	vr_in				 	BOOLEAN,
	vr_out			 		BOOLEAN,
	vr_in_tags			 	BOOLEAN,
	vr_out_tags		 		BOOLEAN,
	vr_count			 	INTEGER,
	vr_lower_boundary	 	INTEGER
)
RETURNS TABLE (
	node_type_id			UUID,
	node_type_additional_id	VARCHAR,
	type_name				VARCHAR,
	nodes_count				INTEGER
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT *
		FROM cn_p_get_related_node_ids(vr_application_id, vr_node_id, vr_related_node_type_id, 
			vr_search_text, vr_in, vr_out, vr_in_tags, vr_out_tags, vr_count, vr_lower_boundary)
	);

	RETURN QUERY
	SELECT *
	FROM (
			SELECT	nd.node_type_id,
					MAX(nd.type_additional_id) AS node_type_additional_id,
					MAX(nd.type_name) AS type_name,
					COUNT(nd.node_id) AS nodes_count
			FROM UNNEST(vr_ids) AS x
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = x
			GROUP BY nd.node_type_id
		) AS x
	ORDER BY x.nodes_count DESC;
END;
$$ LANGUAGE plpgsql;
