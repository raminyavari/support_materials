DROP FUNCTION IF EXISTS cn_is_node_admin;

CREATE OR REPLACE FUNCTION cn_is_node_admin
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN cn_p_is_node_admin(vr_application_id, vr_node_id, vr_user_id);
END;
$$ LANGUAGE plpgsql;

