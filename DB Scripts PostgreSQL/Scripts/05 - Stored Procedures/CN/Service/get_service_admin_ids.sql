DROP FUNCTION IF EXISTS cn_get_service_admin_ids;

CREATE OR REPLACE FUNCTION cn_get_service_admin_ids
(
	vr_application_id	UUID,
	vr_node_type_id		UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT s.user_id AS "id"
	FROM cn_service_admins AS s
	WHERE s.application_id = vr_application_id AND s.deleted = FALSE AND 
		(vr_node_type_id IS NULL OR s.node_type_id = vr_node_type_id);
END;
$$ LANGUAGE plpgsql;
