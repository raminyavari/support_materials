DROP FUNCTION IF EXISTS cn_is_complex_admin;

CREATE OR REPLACE FUNCTION cn_is_complex_admin
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
		SELECT TRUE
		FROM cn_view_list_admins AS l
		WHERE l.application_id = vr_application_id AND l.node_id = vr_node_id AND l.user_id = vr_user_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

