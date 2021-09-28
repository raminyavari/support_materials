DROP FUNCTION IF EXISTS cn_get_members_count;

CREATE OR REPLACE FUNCTION cn_get_members_count
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_status			varchar(20),
    vr_is_admin	 		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(*)
		FROM cn_node_members AS nm 
			INNER JOIN users_normal AS usr 
			ON usr.application_id = vr_application_id AND 
				usr.user_id = nm.user_id AND usr.is_approved = TRUE
		WHERE nm.application_id = vr_application_id AND 
			nm.node_id = vr_node_id AND (vr_status IS NULL OR nm.status = vr_status) AND
			(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin) AND nm.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

