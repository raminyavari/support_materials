DROP FUNCTION IF EXISTS cn_p_get_members;

CREATE OR REPLACE FUNCTION cn_p_get_members
(
	vr_application_id	UUID,
    vr_members			guid_pair_table_type[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF cn_member_ret_composite
AS
$$
BEGIN
	RETURN QUERY
    SELECT 	nm.node_id,
		   	nm.user_id,
		   	nm.membership_date,
		   	nm.is_admin,
		   	CASE WHEN nm.status = 'Pending' THEN TRUE ELSE FALSE END::BOOLEAN AS is_pending,
		   	nm.status,
		   	nm.acception_date,
		   	nm.position,
		   	NULL::VARCHAR AS node_additional_id,
		   	NULL::VARCHAR AS node_name,
			NULL::UUID AS node_type_id,
			NULL::VARCHAR AS node_type,
		   	usr.username,
		   	usr.first_name,
		   	usr.last_name,
		   	vr_total_count AS total_count
    FROM UNNEST(vr_members) AS ext
		INNER JOIN cn_node_members AS nm 
		ON nm.application_id = vr_application_id AND 
			nm.node_id = ext.first_value AND nm.user_id = ext.second_value
		INNER JOIN users_normal AS usr 
		ON usr.application_id = vr_application_id AND usr.user_id = nm.user_id
	ORDER BY usr.last_activity_date DESC;
END;
$$ LANGUAGE plpgsql;
