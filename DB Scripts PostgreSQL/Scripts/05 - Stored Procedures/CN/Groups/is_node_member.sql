DROP FUNCTION IF EXISTS cn_is_node_member;

CREATE OR REPLACE FUNCTION cn_is_node_member
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
	RETURN cn_p_is_node_member(vr_application_id, vr_node_id, vr_user_id, vr_is_admin, vr_status);
END;
$$ LANGUAGE plpgsql;

