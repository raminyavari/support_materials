DROP FUNCTION IF EXISTS de_remove_nodes;

CREATE OR REPLACE FUNCTION de_remove_nodes
(
	vr_application_id	UUID,
	vr_node_ids	 		guid_string_table_type[],
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids		UUID[];
	vr_result	INTEGER;
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT nd.node_id
		FROM UNNEST(vr_node_ids) AS rf
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND 
				nd.type_additional_id = rf.first_value AND nd.node_additional_id = rf.second_value
	);

	UPDATE cn_nodes
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_ids) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

