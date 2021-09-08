DROP FUNCTION IF EXISTS cn_get_node_type;

CREATE OR REPLACE FUNCTION cn_get_node_type
(
	vr_application_id			UUID,
	vr_node_type_id				UUID,
	vr_node_type_additional_id 	VARCHAR(20),
	vr_node_id					UUID
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_node_type_ids	UUID[];
BEGIN
	vr_node_type_id = COALESCE((
		SELECT x.node_type_id
		FROM cn_nodes AS x
		WHERE x.application_id = vr_application_id AND x.node_id = vr_node_type_id
		LIMIT 1
	), vr_node_type_id);
	
	IF vr_node_type_id IS NOT NULL THEN
		vr_node_type_ids := ARRAY(SELECT vr_node_type_id);
	ELSEIF vr_node_id IS NOT NULL THEN
		vr_node_type_ids := ARRAY(
			SELECT nd.node_type_id
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
			LIMIT 1
		);
	ELSE
		vr_node_type_ids := ARRAY(
			SELECT x.node_type_id
			FROM cn_node_types AS x
			WHERE x.application_id = vr_application_id AND x.additional_id = vr_node_type_additional_id 
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_node_type_ids);
END;
$$ LANGUAGE plpgsql;
