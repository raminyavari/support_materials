DROP FUNCTION IF EXISTS cn_get_node_description;

CREATE OR REPLACE FUNCTION cn_get_node_description
(
	vr_application_id	UUID,
    vr_node_id			UUID
)
RETURNS VARCHAR
AS
$$
BEGIN
	SELECT x.description
	FROM cn_nodes AS x
	WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id
	LIMIT 1;
END;
$$ LANGUAGE plpgsql;

