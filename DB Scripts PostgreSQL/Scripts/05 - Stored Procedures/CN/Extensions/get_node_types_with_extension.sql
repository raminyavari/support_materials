DROP FUNCTION IF EXISTS cn_get_node_types_with_extension;

CREATE OR REPLACE FUNCTION cn_get_node_types_with_extension
(
	vr_application_id	UUID,
	vr_extensions		string_table_type[]
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_node_type_ids	UUID[];
BEGIN
	vr_node_type_ids := ARRAY(
		SELECT DISTINCT nt.node_type_id
		FROM UNNEST(vr_extensions) AS e
			INNER JOIN cn_extensions AS x
			ON x.application_id = vr_application_id AND x.extension = e.value AND x.deleted = FALSE
			INNER JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND nt.node_type_id = x.owner_id AND nt.deleted = FALSE
	);
		
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_node_type_ids);
END;
$$ LANGUAGE plpgsql;
