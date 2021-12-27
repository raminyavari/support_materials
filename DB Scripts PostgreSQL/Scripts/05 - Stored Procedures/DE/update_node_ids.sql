DROP FUNCTION IF EXISTS de_update_node_ids;

CREATE OR REPLACE FUNCTION de_update_node_ids
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_node_ids	 		guid_string_table_type[],
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_node_ids := ARRAY(
		SELECT DISTINCT ROW(nd.node_id, rf.second_value)
		FROM UNNEST(vr_node_ids) AS rf
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND 
				nd.node_type_id = vr_node_type_id AND nd.additional_id = rf.first_value
	);

	UPDATE cn_nodes
	SET additional_id = x.second_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM (
			SELECT v.*
			FROM UNNEST(vr_node_ids) AS v
				LEFT JOIN cn_nodes AS n
				ON n.application_id = vr_application_id AND n.node_type_id = vr_node_type_id AND
					n.additional_id = v.second_value AND n.node_id <> v.first_value
			WHERE COALESCE(v.second_value, '') <> '' AND n.node_id IS NULL
		) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.first_value;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

