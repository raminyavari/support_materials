DROP FUNCTION IF EXISTS cn_p_is_node_member;

CREATE OR REPLACE FUNCTION cn_p_is_node_member
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_is_admin	 		BOOLEAN,
    vr_status			VARCHAR(20)
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM cn_node_members AS nm
		WHERE nm.application_id = vr_application_id AND 
			nm.node_id = vr_node_id AND nm.user_id = vr_user_id AND nm.deleted = FALSE AND
			(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin) AND
			(vr_status IS NULL OR nm.status = vr_status)
		LIMIT 1
	), 0)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

