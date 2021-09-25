DROP FUNCTION IF EXISTS cn_get_creator_nodes;

CREATE OR REPLACE FUNCTION cn_get_creator_nodes
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_id		UUID
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_node_ids	UUID[];
BEGIN
	vr_node_ids := ARRAY(
		SELECT nc.node_id
		FROM cn_node_creators AS nc
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
		WHERE nc.application_id = vr_application_id AND nc.user_id = vr_user_id AND 
			(vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
			nc.deleted = FALSE AND nd.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_node_ids, NULL, NULL);
END;
$$ LANGUAGE plpgsql;
