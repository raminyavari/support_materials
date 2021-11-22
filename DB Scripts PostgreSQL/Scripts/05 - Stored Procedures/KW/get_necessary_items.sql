DROP FUNCTION IF EXISTS kw_get_necessary_items;

CREATE OR REPLACE FUNCTION kw_get_necessary_items
(
	vr_application_id			UUID,
    vr_node_type_id_or_node_id	UUID
)
RETURNS SETOF VARCHAR
AS
$$
BEGIN
	vr_node_type_id_or_node_id = COALESCE((
		SELECT nd.node_type_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_type_id_or_node_id
		LIMIT 1
	), vr_node_type_id_or_node_id);
	
	RETURN QUERY
	SELECT ni.item_name
	FROM kw_necessary_items AS ni
	WHERE ni.application_id = vr_application_id AND 
		ni.node_type_id = vr_node_type_id_or_node_id AND ni.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

