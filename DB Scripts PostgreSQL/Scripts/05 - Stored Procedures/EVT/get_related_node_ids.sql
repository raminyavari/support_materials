DROP FUNCTION IF EXISTS evt_get_related_node_ids;

CREATE OR REPLACE FUNCTION evt_get_related_node_ids
(
	vr_application_id			UUID,
    vr_event_id					UUID,
	vr_node_type_additional_id	VARCHAR(20)
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT nd.node_id AS "id"
	FROM evt_related_nodes AS rn
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
	WHERE rn.application_id = vr_application_id AND rn.event_id = vr_event_id AND 
		(vr_node_type_additional_id IS NULL OR  nd.type_additional_id = vr_node_type_additional_id) AND
		rn.deleted = FALSE AND nd.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

