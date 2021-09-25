DROP FUNCTION IF EXISTS cn_get_list_nodes;

CREATE OR REPLACE FUNCTION cn_get_list_nodes
(
	vr_application_id			UUID,
	vr_list_id					UUID,
	vr_node_type_id				UUID,
	vr_node_type_additional_id	VARCHAR(50)
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_node_ids	UUID[];
BEGIN
	IF vr_node_type_id IS NULL AND COALESCE(vr_node_type_additional_id, '') <> '' THEN
		vr_node_type_id := cn_fn_get_node_type_id(vr_application_id, vr_node_type_additional_id);
	END IF;
	
	vr_node_ids := ARRAY(
		SELECT l.node_id
		FROM cn_list_nodes AS l
			INNER JOIN cn_nodes AS node
			ON node.application_id = vr_application_id AND node.node_id = l.node_id
		WHERE l.application_id = vr_application_id AND l.list_id = vr_list_id AND l.deleted = FALSE AND 
			(vr_node_type_id IS NULL OR node.node_type_id = vr_node_type_id) AND node.deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_node_ids, FALSE, NULL);
END;
$$ LANGUAGE plpgsql;
