DROP FUNCTION IF EXISTS kw_set_candidate_relations;

CREATE OR REPLACE FUNCTION kw_set_candidate_relations
(
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_node_type_ids		guid_table_type[],
	vr_node_ids				guid_table_type[],
	vr_current_user_id		UUID,
	vr_now	 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
	vr_result2	INTEGER;
BEGIN
	WITH "data" AS 
	(
		SELECT 	x.value AS node_type_id,
				NULL::UUID AS node_id
		FROM UNNEST(vr_node_type_ids) AS x
		
		UNION ALL
		
		SELECT 	NULL::UUID AS node_type_id,
				x.value AS node_id
		FROM UNNEST(vr_node_ids) AS x
	)
	UPDATE kw_candidate_relations
	SET deleted = CASE WHEN d.node_type_id IS NULL AND d.node_id IS NULL THEN TRUE ELSE FALSE END::BOOLEAN,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM kw_candidate_relations AS cr
		LEFT JOIN "data" AS d
		ON cr.node_type_id = d.node_type_id OR cr.node_id = d.node_id
	WHERE cr.application_id = vr_application_id AND cr.knowledge_type_id = vr_knowledge_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	WITH "data" AS 
	(
		SELECT 	x.value AS node_type_id,
				NULL::UUID AS node_id
		FROM UNNEST(vr_node_type_ids) AS x
		
		UNION ALL
		
		SELECT 	NULL::UUID AS node_type_id,
				x.value AS node_id
		FROM UNNEST(vr_node_ids) AS x
	)
	INSERT INTO kw_candidate_relations (
		application_id,
		"id",
		knowledge_type_id,
		node_id,
		node_type_id,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT 	vr_application_id, 
			gen_random_uuid(), 
			vr_knowledge_type_id, 
			d.node_id, 
			d.node_type_id, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM "data" AS d
		LEFT JOIN kw_candidate_relations AS cr
		ON cr.application_id = vr_application_id AND cr.knowledge_type_id = vr_knowledge_type_id AND 
			(cr.node_type_id = d.node_type_id OR cr.node_id = d.node_id)
	WHERE cr.knowledge_type_id IS NULL;
	
	GET DIAGNOSTICS vr_result2 := ROW_COUNT;
	
	RETURN vr_result + vr_result2;
END;
$$ LANGUAGE plpgsql;

