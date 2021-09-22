DROP FUNCTION IF EXISTS cn_get_user2node_status;

CREATE OR REPLACE FUNCTION cn_get_user2node_status
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_node_id			UUID
)
RETURNS TABLE (
	node_type_id		UUID,
	area_id				UUID,
	is_creator			BOOLEAN,
	is_contributor		BOOLEAN,
	is_expert			BOOLEAN,
	is_member			BOOLEAN,
	is_admin_member		BOOLEAN,
	is_service_admin	BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	nd.node_type_id,
			nd.area_id,
			CASE 
				WHEN nd.creator_user_id = vr_user_id THEN TRUE 
				ELSE FALSE 
			END::BOOLEAN AS is_creator,
			CASE
				WHEN nc.user_id IS NULL THEN FALSE
				ELSE TRUE
			END::BOOLEAN AS is_contributor,
			CASE
				WHEN ex.user_id IS NULL THEN FALSE
				ELSE TRUE
			END::BOOLEAN AS is_expert,
			CASE
				WHEN nm.user_id IS NULL THEN FALSE
				ELSE TRUE
			END::BOOLEAN AS is_member,
			CASE
				WHEN nm.user_id IS NULL OR COALESCE(nm.is_admin, FALSE) = FALSE THEN FALSE
				ELSE TRUE
			END::BOOLEAN AS is_admin_member,
			CASE
				WHEN sa.user_id IS NULL THEN FALSE
				ELSE TRUE
			END::BOOLEAN AS is_service_admin
	FROM cn_nodes AS nd
		LEFT JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND 
			nc.node_id = nd.node_id AND nc.user_id = vr_user_id AND nc.deleted = FALSE
		LEFT JOIN cn_view_experts AS ex
		ON ex.application_id = vr_application_id AND 
			ex.user_id = vr_user_id AND ex.node_id = nd.node_id
		LEFT JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND 
			nm.user_id = vr_user_id AND nm.node_id = nd.node_id AND nm.is_pending = FALSE
		LEFT JOIN cn_service_admins AS sa
		ON sa.application_id = vr_application_id AND 
			sa.node_type_id = nd.node_type_id AND sa.user_id = vr_user_id AND sa.deleted = FALSE
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	LIMIT 1;
END;
$$ LANGUAGE plpgsql;

