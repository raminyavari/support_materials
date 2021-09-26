DROP FUNCTION IF EXISTS cn_get_intellectual_properties_of_friends;

CREATE OR REPLACE FUNCTION cn_get_intellectual_properties_of_friends
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_id		UUID,
	vr_lower_boundary 	INTEGER,
	vr_count		 	INTEGER
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_ret_ids				UUID[];
BEGIN
	IF vr_count IS NULL OR vr_count <= 0 THEN
		vr_count := 10;
	END IF;
	
	vr_ret_ids := ARRAY(
		SELECT rf.node_id
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY nd.creation_date DESC) AS "row_number",
						nd.node_id
				FROM (
						SELECT DISTINCT nc.node_id
						FROM usr_view_friends AS f
							INNER JOIN cn_node_creators AS nc
							ON nc.application_id = vr_application_id AND nc.user_id = f.friend_id
						WHERE f.application_id = vr_application_id AND 
							f.user_id = vr_user_id AND f.are_friends = TRUE AND nc.deleted = FALSE
					) AS nid
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = nid.node_id
					LEFT JOIN cn_services AS s
					ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
				WHERE (vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
					nd.deleted = FALSE AND nd.searchable = TRUE AND 
					COALESCE(nd.hide_creators, FALSE) = FALSE AND COALESCE(s.no_content, FALSE) = FALSE
			) AS rf
		WHERE rf.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY rf.row_number ASC
		LIMIT vr_count
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, NULL, NULL);
END;
$$ LANGUAGE plpgsql;
