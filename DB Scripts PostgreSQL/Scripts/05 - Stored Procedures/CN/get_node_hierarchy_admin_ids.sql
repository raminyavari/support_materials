DROP FUNCTION IF EXISTS cn_get_node_hierarchy_admin_ids;

CREATE OR REPLACE FUNCTION cn_get_node_hierarchy_admin_ids
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_same_type	 	BOOLEAN
)
RETURNS TABLE (
	node_id	UUID, 
	user_id	UUID,
	"level"	INTEGER
)
AS
$$
DECLARE
	vr_node_type_id	UUID;
BEGIN
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_hierarchy_admin_ids(vr_application_id, vr_node_id, vr_same_type);
END;
$$ LANGUAGE plpgsql;
