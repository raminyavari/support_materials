

DROP PROCEDURE IF EXISTS _cn_p_add_relation;

CREATE OR REPLACE PROCEDURE _cn_p_add_relation
(
	vr_application_id		UUID,
	vr_relations			guid_triple_table_type[],
    vr_creator_user_id		UUID,
    vr_creation_date	 	TIMESTAMP,
    vr_set_nulls_to_default	BOOLEAN,
	INOUT vr_result	 		INTEGER
)
AS
$$
DECLARE
	vr_verified_relations 		guid_triple_table_type[];
	vr_related_relation_type_id UUID;
	vr_temp_result				INTEGER;
BEGIN
	vr_result := -1;
	
	IF vr_set_nulls_to_default = TRUE THEN
		vr_related_relation_type_id := cn_fn_get_related_relation_type_id(vr_application_id);
	END IF;
	
	vr_verified_relations := ARRAY(
		SELECT ROW(
				r.first_value,
				r.second_value,
				CASE 
					WHEN vr_set_nulls_to_default = TRUE AND 
						COALESCE(r.third_value, gfn_guid_empty()) == gfn_guid_empty() THEN vr_related_relation_type_id
					ELSE r.third_value
				END
			)
		FROM UNNEST(vr_relations) AS r
	);
	
	UPDATE cn_node_relations
	SET last_modifier_user_id = vr_creator_user_id,
		last_modification_date = vr_creation_date,
		deleted = FALSE
	FROM vr_verified_relations AS vr
		INNER JOIN cn_node_relations AS nr
		ON nr.source_node_id = vr.first_value AND nr.destination_node_id = vr.second_value
	WHERE nr.application_id = vr_application_id AND nr.property_id = vr.third_value;
	
	GET DIAGNOSTICS vr_temp_result := ROW_COUNT;
	
	INSERT INTO cn_node_relations(
		application_id,
		source_node_id,
		destination_node_id,
		property_id,
		creator_user_id,
		creation_date,
		deleted,
		unique_id
	)
	SELECT vr_application_id, vr.first_value, vr.second_value, vr.third_value, 
		vr_creator_user_id, vr_creation_date, FALSE, gen_random_uuid()
	FROM vr_verified_relations AS vr
		LEFT JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.source_node_id = vr.first_value AND 
			nr.destination_node_id = vr.second_value AND nr.property_id = vr.third_value
	WHERE nr.source_ndoe_id IS NULL;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	vr_result := vr_result + vr_temp_result;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_p_add_relation;

CREATE OR REPLACE FUNCTION cn_p_add_relation
(
	vr_application_id		UUID,
	vr_relations			guid_triple_table_type[],
    vr_creator_user_id		UUID,
    vr_creation_date	 	TIMESTAMP,
    vr_set_nulls_to_default	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	CALL _cn_p_add_relation(vr_application_id, vr_relations, vr_creator_user_id,
						   vr_creation_date, vr_set_nulls_to_default, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

