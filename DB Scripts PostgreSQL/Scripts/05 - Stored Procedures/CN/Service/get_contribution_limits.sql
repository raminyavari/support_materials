DROP FUNCTION IF EXISTS cn_get_contribution_limits;

CREATE OR REPLACE FUNCTION cn_get_contribution_limits
(
	vr_application_id		UUID,
	vr_node_id_or_type_id	UUID
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_node_type_id		UUID;
	vr_node_type_ids	UUID[];
BEGIN
	vr_node_type_id := COALESCE((
		SELECT nd.node_type_id 
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id_or_type_id
		LIMIT 1
	), vr_node_id_or_type_id);
	
	vr_node_type_ids := ARRAY(
		SELECT "t".limit_node_type_id
		FROM cn_contribution_limits AS "t"
		WHERE "t".application_id = vr_application_id AND 
			"t".node_type_id = vr_node_type_id AND "t".deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_node_type_ids);
END;
$$ LANGUAGE plpgsql;
