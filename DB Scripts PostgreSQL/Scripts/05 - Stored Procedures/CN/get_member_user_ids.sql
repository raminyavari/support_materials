DROP FUNCTION IF EXISTS cn_get_member_user_ids;

CREATE OR REPLACE FUNCTION cn_get_member_user_ids
(
	vr_application_id	UUID,
    vr_node_ids			guid_table_type[],
    vr_status			VARCHAR(20),
    vr_is_admin	 		BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM cn_p_get_member_user_ids(vr_application_id, vr_node_ids, vr_status, vr_is_admin);
END;
$$ LANGUAGE plpgsql;

