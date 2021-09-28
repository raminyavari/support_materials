DROP FUNCTION IF EXISTS cn_p_update_member;

CREATE OR REPLACE FUNCTION cn_p_update_member
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_user_id			UUID,
    vr_membership_date	TIMESTAMP,
    vr_is_admin		 	BOOLEAN,
    vr_is_pending		BOOLEAN,
    vr_acception_date	TIMESTAMP,
    vr_position		 	VARCHAR(255),
    vr_deleted		 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_members	guid_pair_table_type[];
BEGIN
	vr_members := ARRAY(
		SELECT ROW(vr_node_id, vr_user_id)
	);

	RETURN cn_p_update_members(vr_application_id, vr_members, vr_membership_date, vr_is_admin,
							  vr_is_pending, vr_acception_date, vr_position, vr_deleted);
END;
$$ LANGUAGE plpgsql;

