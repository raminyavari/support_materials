DROP FUNCTION IF EXISTS cn_get_default_connected_nodes;

CREATE OR REPLACE FUNCTION cn_get_default_connected_nodes
(
	vr_application_id	UUID,
	vr_node_id			UUID
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_ret_ids			UUID[];
BEGIN
	vr_ret_ids := ARRAY(
		SELECT nr.destination_node_id
		FROM cn_node_relations AS nr
			INNER JOIN cn_view_nodes_normal AS nodes
			ON nodes.application_id = vr_application_id AND nodes.node_id = nr.destination_node_id
		WHERE nr.application_id = vr_application_id AND nr.source_node_id = vr_node_id AND nr.deleted = FALSE AND 
			nodes.type_additional_id IN ('1', '2', '3', '4') AND nodes.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, FALSE, NULL);
END;
$$ LANGUAGE plpgsql;
