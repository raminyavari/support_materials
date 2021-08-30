DROP FUNCTION IF EXISTS cn_have_child_node_types;

CREATE OR REPLACE FUNCTION cn_have_child_node_types
(
	vr_application_id	UUID,
	vr_node_type_ids	guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT ex.value AS "id"
	FROM UNNEST(vr_node_type_ids) AS ex
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND 
			(nt.parent_id = ex.value AND nt.parent_id <> nt.node_type_id) AND nt.deleted = FALSE
	GROUP BY ex.value;
END;
$$ LANGUAGE plpgsql;
