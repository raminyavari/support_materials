DROP FUNCTION IF EXISTS cn_p_is_node_admin;

CREATE OR REPLACE FUNCTION cn_p_is_node_admin
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT nm.is_admin
		FROM cn_node_members AS nm
		WHERE nm.application_id = vr_application_id AND 
			nm.node_id = vr_node_id AND nm.user_id = vr_user_id AND nm.deleted = FALSE
		LIMIT 1
	), 0)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

