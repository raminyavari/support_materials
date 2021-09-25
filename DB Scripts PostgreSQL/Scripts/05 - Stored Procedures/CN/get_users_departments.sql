DROP FUNCTION IF EXISTS cn_get_users_departments;

CREATE OR REPLACE FUNCTION cn_get_users_departments
(
	vr_application_id	UUID,
    vr_user_ids			guid_table_type[]
)
RETURNS SETOF cn_member_ret_composite
AS
$$
DECLARE
	vr_dep_type_ids	UUID[];
	vr_members		guid_pair_table_type[];
BEGIN
	vr_dep_type_ids := ARRAY(
		SELECT rf.node_type_id
		FROM cn_fn_get_department_node_type_ids(vr_application_id) AS rf
	);

	vr_members := ARRAY(
		SELECT ROW(nm.node_id, nm.user_id)
		FROM UNNEST(vr_user_ids) AS external_ids
			INNER JOIN cn_node_members AS nm 
			ON nm.application_id = vr_application_id AND nm.user_id = external_ids.value
			INNER JOIN cn_view_nodes_normal AS vn 
			ON vn.application_id = vr_application_id AND vn.node_id = nm.node_id
		WHERE vn.node_type_id IN (SELECT UNNEST(vr_dep_type_ids)) AND 
			nm.deleted = FALSE AND vn.deleted = FALSE
	);
		
	RETURN QUERY
	SELECT *
	FROM cn_p_get_member_nodes(vr_application_id, vr_members);
END;
$$ LANGUAGE plpgsql;
