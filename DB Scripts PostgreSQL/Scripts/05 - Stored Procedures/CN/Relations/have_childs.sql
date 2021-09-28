DROP FUNCTION IF EXISTS cn_have_childs;

CREATE OR REPLACE FUNCTION cn_have_childs
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT external_ids.value AS "id"
	FROM UNNEST(vr_node_ids) AS external_ids
	WHERE EXISTS(
		SELECT * 
		FROM cn_nodes  AS nd
		WHERE nd.application_id = vr_application_id AND 
			(nd.parent_node_id = external_ids.value AND nd.parent_node_id <> nd._node_id) AND nd.deleted = FALSE
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

