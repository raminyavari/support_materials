DROP FUNCTION IF EXISTS cn_get_direct_parent;

CREATE OR REPLACE FUNCTION cn_get_direct_parent
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
		SELECT parent.node_id
		FROM cn_nodes AS node
			INNER JOIN cn_nodes AS parent
			ON parent.application_id = vr_application_id AND parent.node_id = node.parent_node_id
		WHERE node.application_id = vr_application_id AND node.node_id = vr_node_id AND 
			node.parent_node_id IS NOT NULL AND parent.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, FALSE, NULL);
END;
$$ LANGUAGE plpgsql;
