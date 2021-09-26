DROP FUNCTION IF EXISTS cn_get_intellectual_properties;

CREATE OR REPLACE FUNCTION cn_get_intellectual_properties
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_ids	guid_table_type[],
	vr_node_id			UUID,
	vr_additional_id	VARCHAR(50),
	vr_current_user_id	UUID,
	vr_search_text		VARCHAR(1000),
	vr_is_document	 	BOOLEAN,
	vr_lower_date_limit TIMESTAMP,
	vr_upper_date_limit TIMESTAMP,
	vr_lower_boundary 	INTEGER,
	vr_count		 	INTEGER
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_nt_count				INTEGER;
	vr_is_system_admin		BOOLEAN;
	vr_service_admin_ids	UUID[];
	vr_ret_ids				UUID[];
	vr_total_count			INTEGER;
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
	
	vr_is_system_admin := gfn_is_system_admin(vr_application_id, vr_current_user_id);
	
	vr_service_admin_ids := ARRAY(
		SELECT DISTINCT s.node_type_id
		FROM cn_service_admins AS s
		WHERE s.application_id = vr_application_id AND 
			s.user_id = vr_current_user_id AND s.deleted = FALSE
	);
	
	WITH "data" AS (
		SELECT 	ROW_NUMBER() OVER (ORDER BY x.rank DESC, x.creation_date DESC, x.node_id DESC) AS "row_number",
				x.node_id
		FROM (
				SELECT	nd.node_id,
						MAX(pgroonga_score(nd.tableoid, nd.ctid)) AS "rank",
						MAX(nd.node_type_id::VARCHAR(50))::UUID AS node_type_id,
						MAX(nd.creation_date) AS creation_date,
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
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id AND (
							COALESCE(vr_search_text, '') = '' OR nd.name &@~ vr_search_text OR
							nd.additional_id &@~ vr_search_text
						)
					LEFT JOIN cn_services AS s
					ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
				WHERE nc.application_id = vr_application_id AND 
					(nc.user_id = vr_user_id OR (
						vr_current_user_id IS NOT NULL AND nc.user_id = vr_current_user_id
					)) AND 
					(vr_node_id IS NULL OR nd.node_id = vr_node_id) AND
					(vr_nt_count = 0 OR nd.node_type_id IN (SELECT x.value FROM UNNEST(vr_node_type_ids) AS x)) AND 
					(vr_additional_id IS NULL OR nd.additional_id = vr_additional_id) AND
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
			(x.searchable = TRUE AND x.hide_creators = FALSE) OR x.cur_user = TRUE)
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
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, NULL, NULL, vr_total_count);
END;
$$ LANGUAGE plpgsql;
