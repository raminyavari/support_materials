DROP FUNCTION IF EXISTS cn_get_existing_node_type_ids;

CREATE OR REPLACE FUNCTION cn_get_existing_node_type_ids
(
	vr_application_id	UUID,
	vr_node_type_ids	guid_table_type[],
	vr_searchable	 	BOOLEAN,
	vr_no_content	 	BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT nt.node_type_id AS "id"
	FROM UNNEST(vr_node_type_ids) AS ids
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ids.value AND nt.deleted = FALSE
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nt.node_type_id AND s.deleted = FALSE
	WHERE (vr_no_content IS NULL OR COALESCE(s.no_content, FALSE) = vr_no_content);
END;
$$ LANGUAGE plpgsql;

