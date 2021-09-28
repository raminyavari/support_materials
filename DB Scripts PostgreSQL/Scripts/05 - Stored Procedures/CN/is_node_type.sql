DROP FUNCTION IF EXISTS cn_is_node_type;

CREATE OR REPLACE FUNCTION cn_is_node_type
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
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = rf.value;
END;
$$ LANGUAGE plpgsql;

