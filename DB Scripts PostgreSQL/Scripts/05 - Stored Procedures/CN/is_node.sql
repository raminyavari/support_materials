DROP FUNCTION IF EXISTS cn_is_node;

CREATE OR REPLACE FUNCTION cn_is_node
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT rf.value AS "id"
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rf.value;
END;
$$ LANGUAGE plpgsql;

