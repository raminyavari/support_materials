DROP FUNCTION IF EXISTS cn_arithmetic_delete_complex_nodes;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_complex_nodes
(
	vr_application_id	UUID,
	vr_list_id			UUID,
    vr_node_ids			guid_table_type[],
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_list_nodes
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_ids) AS nid
		INNER JOIN cn_list_nodes AS l
		ON l.node_id = nid.value
	WHERE l.application_id = vr_application_id AND l.list_id = vr_list_id AND l.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
