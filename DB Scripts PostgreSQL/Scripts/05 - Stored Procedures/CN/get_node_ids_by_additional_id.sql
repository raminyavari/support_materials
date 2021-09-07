DROP FUNCTION IF EXISTS cn_get_node_ids_by_additional_id;

CREATE OR REPLACE FUNCTION cn_get_node_ids_by_additional_id
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
    vr_ids				string_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT x.id AS additional_id, nd.node_id
	FROM (
			SELECT DISTINCT "a".value AS "id"
			FROM UNNEST(vr_ids) AS "a"
		) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_type_id = vr_node_type_id AND nd.additional_id = x.id;
END;
$$ LANGUAGE plpgsql;
