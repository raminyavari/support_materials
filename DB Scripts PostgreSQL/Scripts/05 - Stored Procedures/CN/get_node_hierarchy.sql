DROP FUNCTION IF EXISTS cn_get_node_hierarchy;

CREATE OR REPLACE FUNCTION cn_get_node_hierarchy
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_same_type 		BOOLEAN
)
RETURNS TABLE (
	"id"		UUID, 
	parent_id	UUID, 
	"level"		VARCHAR, 
	"name"		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT x.id, x.parent_id, x.level, x.name
	FROM cn_p_get_node_hierarchy(vr_application_id, vr_node_id, vr_same_type) AS x;
END;
$$ LANGUAGE plpgsql;

