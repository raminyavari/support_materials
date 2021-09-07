DROP FUNCTION IF EXISTS cn_arithmetic_delete_nodes;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_nodes
(
	vr_application_id	UUID,
    vr_node_ids			guid_table_type[],
    vr_remove_hierarchy	BOOLEAN,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids		UUID[];
	vr_result	INTEGER = 0;
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_node_ids) AS x
	);
	
	CALL _cn_p_arithmetic_delete_nodes(vr_application_id, vr_ids, vr_remove_hierarchy, 
									   vr_current_user_id, vr_now, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

