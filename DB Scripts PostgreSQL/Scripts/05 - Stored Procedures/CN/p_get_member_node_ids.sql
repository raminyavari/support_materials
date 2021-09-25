DROP FUNCTION IF EXISTS cn_p_get_member_node_ids;

CREATE OR REPLACE FUNCTION cn_p_get_member_node_ids
(
	vr_application_id			UUID,
    vr_user_id					UUID,
    vr_node_type_additional_id	VARCHAR(20),
    vr_status					VARCHAR(20),
    vr_is_admin			 		BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
    SELECT nm.node_id AS "id"
    FROM cn_node_members AS nm 
		INNER JOIN cn_view_nodes_normal AS vn 
		ON vn.application_id = vr_application_id AND vn.node_id = nm.node_id AND 
			(vr_node_type_additional_id IS NULL OR vn.type_additional_id = vr_node_type_additional_id) AND 
			vn.deleted = FALSE
	WHERE nm.application_id = vr_application_id AND nm.user_id = vr_user_id AND 
		(vr_status IS NULL OR nm.status = vr_status) AND
		(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin) AND nm.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;
