DROP FUNCTION IF EXISTS cn_is_free_user;

CREATE OR REPLACE FUNCTION cn_is_free_user
(
	vr_application_id			UUID,
	vr_node_type_id_or_node_id	UUID,
	vr_user_id					UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	vr_node_type_id_or_node_id := COALESCE((
		SELECT nd.node_type_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_type_id_or_node_id
		LIMIT 1
	), vr_node_type_id_or_node_id);

	RETURN COALESCE((
		SELECT TRUE
		FROM cn_free_users AS f
		WHERE f.application_id = vr_application_id AND 
			f.node_type_id = vr_node_type_id_or_node_id AND f.user_id = vr_user_id AND f.deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;
