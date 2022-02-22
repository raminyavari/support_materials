DROP FUNCTION IF EXISTS de_update_relations;

CREATE OR REPLACE FUNCTION de_update_relations
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_relations		exchange_relation_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_relation_type_id	UUID;
	vr_result_1			INTEGER;
	vr_result_2			INTEGER;
BEGIN
	vr_relation_type_id := cn_fn_get_related_relation_type_id(vr_application_id);
	
	UPDATE cn_node_relations
	SET last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		deleted = FALSE
	FROM (
			SELECT DISTINCT *
			FROM (
				SELECT	"a".source_type_additional_id,
						"a".source_additional_id,
						"a".destination_type_additional_id,
						"a".destination_additional_id
				FROM UNNEST(vr_relations) AS "a"
				
				UNION ALL
				
				SELECT	"a".destination_type_additional_id,
						"a".destination_additional_id,
						"a".source_type_additional_id,
						"a".source_additional_id
				FROM UNNEST(vr_relations) AS "a"
				WHERE "a".bidirectional = TRUE
			) AS x
		) AS r
		INNER JOIN cn_node_types AS snt
		ON snt.application_id = vr_application_id AND snt.additional_id = r.source_type_additional_id
		INNER JOIN cn_nodes AS snd
		ON snd.application_id = vr_application_id AND snd.node_type_id = snt.node_type_id AND
			snd.additional_id = r.source_additional_id
		INNER JOIN cn_node_types AS dnt
		ON dnt.application_id = vr_application_id AND 
			dnt.additional_id = r.destination_type_additional_id
		INNER JOIN cn_nodes AS dnd
		ON dnd.application_id = vr_application_id AND dnd.node_type_id = dnt.node_type_id AND
			dnd.additional_id = r.destination_additional_id
		INNER JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.source_node_id = snd.node_id AND
			nr.destination_node_id = dnd.node_id AND nr.property_id = vr_relation_type_id;
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	INSERT INTO cn_node_relations (
		application_id,
		source_node_id,
		destination_node_id,
		property_id,
		creator_user_id,
		creation_date,
		deleted,
		unique_id
	)
	SELECT	vr_application_id, 
			snd.node_id, 
			dnd.node_id, 
			vr_relation_type_id, 
			vr_current_user_id, 
			vr_now, 
			FALSE, 
			gen_random_uuid()
	FROM (
			SELECT DISTINCT *
			FROM (
				SELECT	"a".source_type_additional_id,
						"a".source_additional_id,
						"a".destination_type_additional_id,
						"a".destination_additional_id
				FROM UNNEST(vr_relations) AS "a"
				
				UNION ALL
				
				SELECT	"a".destination_type_additional_id,
						"a".destination_additional_id,
						"a".source_type_additional_id,
						"a".source_additional_id
				FROM UNNEST(vr_relations) AS "a"
				WHERE "a".bidirectional = TRUE
			) AS x
		) AS r
		INNER JOIN cn_node_types AS snt
		ON snt.application_id = vr_application_id AND snt.additional_id = r.source_type_additional_id
		INNER JOIN cn_nodes AS snd
		ON snd.application_id = vr_application_id AND snd.node_type_id = snt.node_type_id AND
			snd.additional_id = r.source_additional_id
		INNER JOIN cn_node_types AS dnt
		ON dnt.application_id = vr_application_id AND 
			dnt.additional_id = r.destination_type_additional_id
		INNER JOIN cn_nodes AS dnd
		ON dnd.application_id = vr_application_id AND dnd.node_type_id = dnt.node_type_id AND
			dnd.additional_id = r.destination_additional_id
		LEFT JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.source_node_id = snd.node_id AND
			nr.destination_node_id = dnd.node_id AND nr.property_id = vr_relation_type_id
	WHERE nr.source_node_id IS NULL;
	
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;

	RETURN COALESCE(vr_result_1, 0)::INTEGER + COALESCE(vr_result_2, 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

