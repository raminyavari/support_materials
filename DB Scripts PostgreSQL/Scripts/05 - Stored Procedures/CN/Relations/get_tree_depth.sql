DROP FUNCTION IF EXISTS cn_get_tree_depth;

CREATE OR REPLACE FUNCTION cn_get_tree_depth
(
	vr_application_id	UUID,
	vr_node_type_id 	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_node_ids	UUID[];
BEGIN
	vr_node_ids := ARRAY(
		SELECT nd.node_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_type_id = vr_node_type_id AND 
			nd.parent_node_id IS NULL AND nd.deleted = FALSE
	);
	
	RETURN COALESCE((
		SELECT MAX("ref".level) + 1
		FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_node_ids) AS "ref"
		LIMIT 1
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

