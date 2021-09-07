DROP FUNCTION IF EXISTS cn_get_node_ids_by_additional_ids;

CREATE OR REPLACE FUNCTION cn_get_node_ids_by_additional_ids
(
	vr_application_id	UUID,
	vr_nodes			string_pair_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT nd.node_id AS "id"
	FROM UNNEST(vr_nodes) AS rf
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_additional_id = rf.first_value AND nd.type_additional_id = rf.second_value;
END;
$$ LANGUAGE plpgsql;
