DROP FUNCTION IF EXISTS cn_get_parent_nodes;

CREATE OR REPLACE FUNCTION cn_get_parent_nodes
(
	vr_application_id	UUID,
	vr_node_id			UUID
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_node_type_id		UUID;
	vr_child_type_id 	UUID;
	vr_ret_ids			UUID[];
BEGIN
	SELECT vr_node_type_id = nd.node_type_id 
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	LIMIT 1;
	
	vr_child_type_id := cn_fn_get_child_relation_type_id(vr_application_id);

	vr_ret_ids := ARRAY(
		SELECT nr.destination_node_id
		FROM cn_node_relations AS nr
			INNER JOIN cn_nodes AS nodes
			ON nodes.application_id = vr_application_id AND nodes.node_id = nr.destination_node_id
		WHERE nr.application_id = vr_application_id AND 
			nr.source_node_id = vr_node_id AND nr.property_id = vr_child_type_id AND
			nr.deleted = FALSE AND nodes.node_type_id = vr_node_type_id AND nodes.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, FALSE, NULL);
END;
$$ LANGUAGE plpgsql;
