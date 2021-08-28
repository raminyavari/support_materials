
DROP FUNCTION IF EXISTS cn_get_child_node_types;

CREATE OR REPLACE FUNCTION cn_get_child_node_types
(
	vr_application_id	UUID,
	vr_parent_id		UUID,
	vr_archive 			BOOLEAN
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_ret_ids	UUID[];
BEGIN
	vr_ret_ids := ARRAY(
		SELECT node_type_id
		FROM cn_node_types
		WHERE application_id = vr_application_id AND
			((vr_parent_id IS NULL AND parent_id IS NULL) OR parent_id = vr_parent_id) AND 
			(vr_archive IS NULL OR deleted = vr_archive)
		ORDER BY sequence_number ASC, creation_date ASC
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_ret_ids);
END;
$$ LANGUAGE plpgsql;

