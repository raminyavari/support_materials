DROP FUNCTION IF EXISTS cn_p_get_member_nodes;

CREATE OR REPLACE FUNCTION cn_p_get_member_nodes
(
	vr_application_id	UUID,
    vr_node_user_ids	guid_pair_table_type[]
)
RETURNS SETOF cn_member_ret_composite
AS
$$
BEGIN
    SELECT 	nm.node_id,
		   	nm.user_id,
		   	nm.membership_date,
		   	nm.is_admin,
		   	CASE WHEN nm.status = 'Pending' THEN TRUE ELSE FALSE END::BOOLEAN AS is_pending,
		   	nm.status,
		   	nm.acception_date,
		   	nm.position,
		   	vn.node_additional_id,
		   	vn.node_name,
		   	vn.node_type_id,
		   	vn.type_name AS node_type,
		   	NULL::VARCHAR AS username,
		   	NULL::VARCHAR AS first_name,
		   	NULL::VARCHAR AS last_name,
		   	NULL::INTEGER AS total_count
    FROM UNNEST(vr_node_user_ids) AS external_ids
		INNER JOIN cn_node_members AS nm 
		ON nm.application_id = vr_application_id AND
			nm.node_id = external_ids.first_value AND nm.user_id = external_ids.second_value
		INNER JOIN cn_view_nodes_normal AS vn 
		ON vn.application_id = vr_application_id AND vn.node_id = nm.node_id;
END;
$$ LANGUAGE plpgsql;
