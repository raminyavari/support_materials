DROP FUNCTION IF EXISTS cn_get_user_managed_node_ids;

CREATE OR REPLACE FUNCTION cn_get_user_managed_node_ids
(
	vr_application_id	UUID,
    vr_user_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
    SELECT nm.node_id
    FROM cn_node_members AS nm
    WHERE nm.application_id = vr_application_id AND nm.user_id = vr_user_id AND nm.is_admin = TRUE;
END;
$$ LANGUAGE plpgsql;
