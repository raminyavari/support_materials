DROP FUNCTION IF EXISTS cn_get_new_versions;

CREATE OR REPLACE FUNCTION cn_get_new_versions
(
	vr_application_id	UUID,
    vr_node_id			UUID
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_node_ids			UUID[];
BEGIN
	vr_node_ids := ARRAY(
		SELECT node_id
		FROM cn_nodes
		WHERE application_id = vr_application_id AND previous_version_id = vr_node_id AND deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_node_ids, NULL, NULL);
END;
$$ LANGUAGE plpgsql;

