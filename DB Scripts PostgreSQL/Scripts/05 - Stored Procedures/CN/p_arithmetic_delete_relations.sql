DROP FUNCTION IF EXISTS cn_p_arithmetic_delete_relations;

CREATE OR REPLACE FUNCTION cn_p_arithmetic_delete_relations
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_relation_type_id UUID,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
    vr_reverse_also		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_pair_ids guid_pair_table_type[];
	vr_result	INTEGER = 0;
BEGIN
	vr_pair_ids := ARRAY(
		SELECT ROW(r.first_value, r.second_value)
		FROM UNNEST(vr_pair_node_ids) AS r
		
		UNION ALL
		
		SELECT ROW(r.second_value, r.first_value)
		FROM UNNEST(vr_pair_node_ids) AS r
			LEFT JOIN UNNEST(vr_pair_node_ids) AS pn
			ON pn.first_value = r.second_value AND pn.second_value = r.first_value
		WHERE COALESCE(vr_reverse_also, FALSE) = TRUE AND pn.first_value IS NULL
	);
	
	UPDATE cn_node_relations
	SET last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		deleted = TRUE
	FROM UNNEST(vr_pair_ids) AS ex
		INNER JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.source_node_id = ex.first_value AND
			nr.destination_node_id = ex.second_value
	WHERE (vr_relation_type_id IS NULL OR nr.property_id = vr_relation_type_id) AND nr.deleted = FALSE;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

