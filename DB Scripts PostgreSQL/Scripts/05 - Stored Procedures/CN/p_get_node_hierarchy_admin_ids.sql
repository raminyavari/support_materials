DROP FUNCTION IF EXISTS cn_p_get_node_hierarchy_admin_ids;

CREATE OR REPLACE FUNCTION cn_p_get_node_hierarchy_admin_ids
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_same_type	 	BOOLEAN
)
RETURNS TABLE (
	node_id	UUID, 
	user_id	UUID,
	"level"	INTEGER
)
AS
$$
DECLARE
	vr_node_type_id	UUID;
BEGIN
	IF vr_same_type = TRUE THEN
		SELECT vr_node_type_id = nd.node_type_id 
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		LIMIT 1;
	END IF;

	RETURN QUERY
	WITH "hierarchy" AS (
		SELECT x.id, x.parent_id, x.level, x.name
		FROM cn_p_get_node_hierarchy(vr_application_id, vr_node_id, vr_same_type) AS x
	),
	admins AS (
		SELECT DISTINCT nm.node_id, nm.user_id
		FROM vr_nodeHierarchy AS hrc
			INNER JOIN cn_node_members AS nm 
			ON nm.application_id = vr_application_id AND nm.node_id = hrc.node_id
			INNER JOIN users_normal AS usr 
			ON usr.application_id = vr_application_id AND usr.user_id = nm.user_id
		WHERE nm.is_admin = TRUE AND nm.deleted = FALSE AND usr.is_approved = TRUE
	)
    SELECT nh.id AS node_id, ad.user_id, nh.level::INTEGER
    FROM "hierarchy" AS nh
		INNER JOIN admins AS ad
		ON nh.id = ad.node_id 
	ORDER BY nh.level ASC;
END;
$$ LANGUAGE plpgsql;
