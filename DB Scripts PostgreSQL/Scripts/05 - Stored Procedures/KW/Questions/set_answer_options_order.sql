DROP FUNCTION IF EXISTS kw_set_answer_options_order;

CREATE OR REPLACE FUNCTION kw_set_answer_options_order
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_question_id 	UUID;
	vr_node_id 		UUID;
	vr_result		INTEGER;
BEGIN
	SELECT vr_question_id = ao.type_question_id
	FROM kw_answer_options AS ao
	WHERE ao.application_id = vr_application_id AND 
		ao.id = (SELECT x.value FROM UNNEST(vr_ids) AS x LIMIT 1)
	LIMIT 1;
	
	IF vr_question_id IS NULL THEN
		RETURN -1::INTEGER;
	END IF;
	
	vr_ids := ARRAY(
		SELECT x.value AS "id"
		FROM UNNEST(vr_ids) WITH ORDINALITY AS x("value", seq)
		
		UNION ALL
		
		SELECT ao.id AS "id"
		FROM UNNEST(vr_ids) AS rf
			RIGHT JOIN kw_answer_options AS ao
			ON ao.id = rf.value
		WHERE ao.application_id = vr_application_id AND 
			ao.type_question_id = vr_question_id AND rf.value IS NULL
		ORDER BY ao.sequence_number
	);
	
	UPDATE kw_answer_options
	SET sequence_number = rf.seq
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf("value", seq)
		INNER JOIN kw_answer_options AS ap
		ON ao.id = rf.value
	WHERE ao.application_id = vr_application_id AND ao.type_question_id = vr_question_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

