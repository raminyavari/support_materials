DROP FUNCTION IF EXISTS cn_get_node_types_by_ids;

CREATE OR REPLACE FUNCTION cn_get_node_types_by_ids
(
	vr_application_id		UUID,
	vr_node_type_ids		guid_table_type[],
	vr_grab_sub_node_types 	BOOLEAN
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_ret_ids	UUID[];
BEGIN
	vr_ret_ids := ARRAY(
		SELECT DISTINCT nt.value
		FROM UNNEST(vr_node_type_ids) AS nt
	);

	IF vr_grab_sub_node_types = TRUE THEN
		vr_ret_ids := ARRAY(
			SELECT UNNEST(vr_ret_ids) AS x
			
			UNION ALL
			
			SELECT DISTINCT rf.node_type_id
			FROM UNNEST(vr_node_type_ids) AS nt
				RIGHT JOIN cn_fn_get_child_node_types_deep_hierarchy(vr_application_id, vr_ret_ids) AS rf
				ON rf.node_type_id = nt
			WHERE nt IS NULL
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_ret_ids);
END;
$$ LANGUAGE plpgsql;

