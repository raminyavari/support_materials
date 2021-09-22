DROP FUNCTION IF EXISTS cn_has_admin;

CREATE OR REPLACE FUNCTION cn_has_admin
(
	vr_application_id	UUID,
    vr_node_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM cn_node_members AS nm
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = nm.user_id AND nm.is_approved = TRUE
		WHERE nm.application_id = vr_application_id AND 
			nm.node_id = vr_node_id AND nm.is_admin = TRUE AND 
			nm.deleted = FALSE AND nm.status <> 'Pending'
		LIMIT 1
	), 0)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

