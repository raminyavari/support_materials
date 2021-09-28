DROP FUNCTION IF EXISTS cn_add_nodes_to_complex;

CREATE OR REPLACE FUNCTION cn_add_nodes_to_complex
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
	vr_ids 	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_node_ids) AS x
	);
	
	RETURN cn_p_add_nodes_to_list(vr_application_id, vr_list_id, vr_ids, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;
