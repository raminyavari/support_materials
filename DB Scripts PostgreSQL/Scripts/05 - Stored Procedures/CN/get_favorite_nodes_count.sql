DROP FUNCTION IF EXISTS cn_get_favorite_nodes_count;

CREATE OR REPLACE FUNCTION cn_get_favorite_nodes_count
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_id		UUID,
	vr_node_id			UUID,
	vr_additional_id	VARCHAR(50),
	vr_is_document	 	BOOLEAN,
	vr_lower_date_limit TIMESTAMP,
	vr_upper_date_limit TIMESTAMP
)
RETURNS TABLE (
	node_type_id			UUID, 
	node_type_additional_id	VARCHAR,
	type_name				VARCHAR, 
	nodes_count				INTEGER
)
AS
$$
BEGIN
	IF vr_node_id IS NOT NULL THEN 
		vr_node_type_id := NULL;
	END IF;
	
	IF vr_node_id IS NOT NULL OR vr_additional_id = '' THEN
		vr_additional_id = NULL;
	END IF;
	
	RETURN QUERY
	SELECT	nd.node_type_id, 
			MAX(nd.type_additional_id)::VARCHAR AS node_type_additional_id,
			MAX(nd.type_name)::VARCHAR AS type_name, 
			COUNT(nd.node_id)::INTEGER AS nodes_count
	FROM cn_node_likes AS nl
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nl.node_id
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
	WHERE nl.application_id = vr_application_id AND nl.user_id = vr_user_id AND 
		(vr_node_id IS NULL OR nd.node_id = vr_node_id) AND
		(vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
		(vr_additional_id IS NULL OR nd.node_additional_id = vr_additional_id) AND
		(vr_is_document IS NULL OR COALESCE(s.is_document, FALSE) = vr_is_document) AND
		(vr_lower_date_limit IS NULL OR nd.creation_date >= vr_lower_date_limit) AND
		(vr_upper_date_limit IS NULL OR nd.creation_date < vr_upper_date_limit) AND
		 nl.deleted = FALSE AND nd.deleted = FALSE
	GROUP BY nd.node_type_id;
END;
$$ LANGUAGE plpgsql;
