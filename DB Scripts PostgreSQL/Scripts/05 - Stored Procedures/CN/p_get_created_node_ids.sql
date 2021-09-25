DROP FUNCTION IF EXISTS cn_p_get_created_node_ids;

CREATE OR REPLACE FUNCTION cn_p_get_created_node_ids
(
	vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT x.id
	FROM (
			SELECT nd.node_id AS "id"
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND 
				nd.creator_user_id = vr_user_id AND nd.deleted = FALSE

			UNION ALL

			SELECT nc.node_id AS "id"
			FROM cn_node_creators AS nc
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
			WHERE nc.application_id = vr_application_id AND nc.user_id = vr_user_id AND nc.deleted = FALSE AND 
				nd.creator_user_id <> vr_user_id AND nd.deleted = FALSE
		) AS x;
END;
$$ LANGUAGE plpgsql;
