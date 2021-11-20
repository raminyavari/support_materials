DROP FUNCTION IF EXISTS kw_set_questions_order;

CREATE OR REPLACE FUNCTION kw_set_questions_order
(
	vr_application_id		UUID,
	vr_ids					guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_knowledge_type_id 	UUID;
	vr_node_id 				UUID;
	vr_result				INTEGER;
BEGIN
	SELECT 	vr_knowledge_type_id = tq.knowledge_type_id, 
			vr_node_id = tq.node_id
	FROM kw_type_questions AS tq
	WHERE tq.application_id = vr_application_id AND 
		tq.id = (SELECT x.value FROM UNNEST(vr_ids) AS x LIMIT 1)
	LIMIT 1;
	
	IF vr_knowledge_type_id IS NULL THEN
		RETURN -1::INTEGER;
	END IF;
	
	vr_ids := ARRAY(
		SELECT x.value AS "id"
		FROM UNNEST(vr_ids) WITH ORDINALITY AS x("value", seq)
		
		UNION ALL
		
		SELECT tq.id AS "id"
		FROM UNNEST(vr_ids) AS rf
			RIGHT JOIN kw_type_questions AS tq
			ON tq.id = rf.value
		WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND 
			((vr_node_id IS NULL AND tq.node_id IS NULL) OR tq.node_id = vr_node_id) AND rf.value IS NULL
		ORDER BY tq.sequence_number
	);
	
	UPDATE kw_type_questions
	SET sequence_number = rf.seq
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf("value", seq)
		INNER JOIN kw_type_questions AS tq
		ON tq.id = rf.value
	WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND 
		((vr_node_id IS NULL AND tq.node_id IS NULL) OR tq.node_id = vr_node_id);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

