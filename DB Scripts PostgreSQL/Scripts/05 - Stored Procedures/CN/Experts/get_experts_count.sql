DROP FUNCTION IF EXISTS cn_get_experts_count;

CREATE OR REPLACE FUNCTION cn_get_experts_count
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_distinct_users 	BOOLEAN,
	vr_approved	 		BOOLEAN,
	vr_social_approved 	BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	IF vr_distinct_users = TRUE THEN
		RETURN COALESCE((
			SELECT COUNT(*) 
			FROM (
					SELECT COUNT(*) AS cnt 
					FROM cn_experts AS ex
						INNER JOIN users_normal AS un
						ON un.application_id = vr_application_id AND un.user_id = ex.user_id
						INNER JOIN cn_view_nodes_normal AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
					WHERE ex.application_id = vr_application_id AND 
						(vr_node_id IS NULL OR ex.node_id = vr_node_id) AND
						((vr_approved = TRUE AND ex.approved = TRUE) OR 
						(vr_social_approved = TRUE AND ex.social_approved = TRUE)) AND
						un.is_approved = TRUE AND nd.deleted = FALSE
					GROUP BY un.user_id
				) AS rf
		), 0)::INTEGER;
	ELSE
		RETURN COALESCE((
			SELECT COUNT(*) 
			FROM cn_experts AS ex
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ex.user_id
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
			WHERE ex.application_id = vr_application_id AND 
				(vr_node_id IS NULL OR ex.node_id = vr_node_id) AND
				((vr_approved = TRUE AND ex.approved = TRUE) OR 
				(vr_social_approved = TRUE AND ex.social_approved = TRUE)) AND
				un.is_approved = TRUE AND nd.deleted = FALSE
		), 0)::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;
