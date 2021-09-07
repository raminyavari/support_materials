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
	SELECT description
	FROM cn_nodes
	WHERE application_id = vr_application_id AND node_id = vr_node_id
	LIMIT 1;
END;
$$ LANGUAGE plpgsql;

