DROP FUNCTION IF EXISTS cn_get_membership_requests_dashboards_count;

CREATE OR REPLACE FUNCTION cn_get_membership_requests_dashboards_count
(
	vr_application_id	UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_node_ids	UUID[];
BEGIN
	vr_node_ids := ARRAY(
		SELECT *
		FROM cn_get_user_managed_node_ids(vr_application_id, vr_user_id)
	);

	RETURN COALESCE((
		SELECT COUNT(nm.node_id)
		FROM UNNEST(vr_node_ids) AS x 
			INNER JOIN cn_node_members AS nm 
			ON nm.application_id = vr_application_id AND nm.node_id = x
			INNER JOIN users_normal AS usr 
			ON usr.application_id = vr_application_id AND usr.user_id = nm.user_id
			INNER JOIN cn_view_nodes_normal AS vn 
			ON vn.application_id = vr_application_id AND vn.node_id = nm.node_id
		WHERE nm.status = 'Pending' AND nm.deleted = FALSE AND 
			usr.is_approved = TRUE AND vn.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;
