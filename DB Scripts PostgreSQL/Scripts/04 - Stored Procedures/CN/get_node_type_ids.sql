DROP FUNCTION IF EXISTS cn_get_node_type_ids;

CREATE OR REPLACE FUNCTION cn_get_node_type_ids
(
	vr_application_id			UUID,
	vr_node_type_additional_ids string_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT x.id
	FROM (
			SELECT cn_fn_get_node_type_id(vr_application_id, rf.value) AS "id"
			FROM UNNEST(vr_node_type_additional_ids) AS rf
		) AS x
	WHERE x.id IS NOT NULL;
END;
$$ LANGUAGE plpgsql;
