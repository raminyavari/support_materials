DROP FUNCTION IF EXISTS cn_p_get_member_user_ids;

CREATE OR REPLACE FUNCTION cn_p_get_member_user_ids
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
	SELECT DISTINCT nm.user_id AS "id"
    FROM UNNEST(vr_node_ids) AS external_ids
		INNER JOIN cn_node_members AS nm 
		ON nm.application_id = vr_application_id AND nm.node_id = external_ids.value
		INNER JOIN users_normal AS usr 
		ON usr.application_id = vr_application_id AND 
			usr.user_id = nm.user_id AND usr.is_approved = TRUE
	WHERE (vr_status IS NULL OR nm.status = vr_status) AND
		(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin) AND nm.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

