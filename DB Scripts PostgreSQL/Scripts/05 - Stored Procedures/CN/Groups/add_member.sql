DROP FUNCTION IF EXISTS cn_get_member;

CREATE OR REPLACE FUNCTION cn_get_member
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID
)
RETURNS SETOF cn_member_ret_composite
AS
$$
DECLARE
	vr_members	guid_pair_table_type[];
BEGIN
	vr_members := ARRAY(
		SELECT ROW(nm.node_id, nm.user_id)
		FROM cn_node_members AS nm
		WHERE nm.application_id = vr_application_id AND 
			nm.node_id = vr_node_id AND nm.user_id = vr_user_id AND nm.deleted = FALSE
	);
		
	RETURN QUERY
	SELECT *
	FROM cn_p_get_members(vr_application_id, vr_members);
END;
$$ LANGUAGE plpgsql;
