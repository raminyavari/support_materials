DROP FUNCTION IF EXISTS cn_get_existing_node_ids;

CREATE OR REPLACE FUNCTION cn_get_existing_node_ids
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[],
	vr_searchable	 	BOOLEAN,
	vr_no_content	 	BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT nd.node_id AS "id"
	FROM UNNEST(vr_node_ids) AS ids
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ids.value AND nd.deleted = FALSE
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
	WHERE (vr_searchable IS NULL OR COALESCE(nd.searchable, TRUE) = vr_searchable) AND
		(vr_no_content IS NULL OR COALESCE(s.no_content, FALSE) = vr_no_content);
END;
$$ LANGUAGE plpgsql;

