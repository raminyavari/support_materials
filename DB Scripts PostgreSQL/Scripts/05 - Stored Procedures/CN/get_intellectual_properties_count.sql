DROP FUNCTION IF EXISTS cn_get_intellectual_properties_count;

CREATE OR REPLACE FUNCTION cn_get_intellectual_properties_count
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_id		UUID,
	vr_node_id			UUID,
	vr_additional_id	VARCHAR(50),
	vr_current_user_id	UUID,
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
DECLARE
	vr_is_system_admin		BOOLEAN;
	vr_service_admin_ids	UUID[];
BEGIN
	IF vr_node_id IS NOT NULL THEN 
		vr_node_type_id := NULL;
	END IF;
	
	IF vr_node_id IS NOT NULL OR vr_additional_id = '' THEN
		vr_additional_id = NULL;
	END IF;
	
	vr_is_system_admin := gfn_is_system_admin(vr_application_id, vr_current_user_id);
	
	vr_service_admin_ids := ARRAY(
		SELECT DISTINCT s.node_type_id
		FROM cn_service_admins AS s
		WHERE s.application_id = vr_application_id AND 
			s.user_id = vr_current_user_id AND s.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT	x.node_type_id,
			MAX(x.node_type_additional_id) AS node_type_additional_id,
			MAX(x.type_name) AS type_name,
			COUNT(x.node_id) AS nodes_count
	FROM (
			SELECT	nd.node_id,
					MAX(nd.node_type_id::VARCHAR(50))::UUID AS node_type_id,
					MAX(nd.type_additional_id) AS node_type_additional_id,
					MAX(nd.type_name) AS type_name,
					MAX(nd.searchable::INTEGER)::BOOLEAN AS searchable,
					MAX(nd.hide_creators::INTEGER)::BOOLEAN AS hide_creators,
					MAX(
						CASE 
							WHEN vr_current_user_id IS NOT NULL AND nc.user_id = vr_current_user_id THEN 1 
							ELSE 0
						END::INTEGER
					)::BOOLEAN AS cur_user,
					MAX(CASE WHEN nc.user_id = vr_user_id THEN 1 ELSE 0 END::INTEGER)::BOOLEAN AS the_user
			FROM cn_node_creators AS nc
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
				LEFT JOIN cn_services AS s
				ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
			WHERE nc.application_id = vr_application_id AND 
				(nc.user_id = vr_user_id OR (
					vr_current_user_id IS NOT NULL AND nc.user_id = vr_current_user_id
				)) AND 
				(vr_node_id IS NULL OR nd.node_id = vr_node_id) AND
				(vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
				(vr_additional_id IS NULL OR nd.node_additional_id = vr_additional_id) AND
				(vr_is_document IS NULL OR COALESCE(s.is_document, FALSE) = vr_is_document) AND
				(vr_lower_date_limit IS NULL OR nd.creation_date >= vr_lower_date_limit) AND
				(vr_upper_date_limit IS NULL OR nd.creation_date < vr_upper_date_limit) AND
				nc.deleted = FALSE AND nd.deleted = FALSE
			GROUP BY nd.node_id
		) AS x
		LEFT JOIN UNNEST(vr_service_admin_ids) AS s
		ON s = x.node_type_id
		LEFT JOIN cn_services AS sss
		ON sss.application_id = vr_application_id AND x.node_type_id = sss.node_type_id AND sss.deleted = FALSE
	WHERE COALESCE(sss.no_content, FALSE) = FALSE AND x.the_user = TRUE AND 
		(vr_is_system_admin = TRUE OR s IS NOT NULL OR 
			(x.searchable = TRUE AND x.hide_creators = FALSE) OR x.cur_user = TRUE
		)
	GROUP BY x.node_type_id;
END;
$$ LANGUAGE plpgsql;

