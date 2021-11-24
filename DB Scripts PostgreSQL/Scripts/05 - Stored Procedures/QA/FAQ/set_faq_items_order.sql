DROP FUNCTION IF EXISTS qa_set_faq_items_order;

CREATE OR REPLACE FUNCTION qa_set_faq_items_order
(
	vr_application_id	UUID,
	vr_category_id		UUID,
	vr_question_ids		guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_initial_count	INTEGER;
	vr_result			INTEGER;
BEGIN
	vr_question_ids := ARRAY(
		SELECT DISTINCT x
		FROM UNNEST(vr_question_ids) AS x
	);
	
	vr_initial_count := COALESCE(ARRAY_LENGTH(vr_question_ids, 1), 0)::INTEGER;

	WITH "data" AS
	(
		SELECT 	rf.seq::INTEGER AS seq,
				rf.value AS question_id
		FROM UNNEST(vr_question_ids) WITH ORDINALITY AS rf("value", seq)
		
		UNION ALL
		
		SELECT 	(ROW_NUMBER() OVER (ORDER BY i.sequence_number ASC))::INTEGER + vr_initial_count AS seq,
				i.question_id
		FROM UNNEST(vr_question_ids) AS rf
			RIGHT JOIN qa_faq_items AS i
			ON i.application_id = vr_application_id AND i.question_id = rf.value
		WHERE i.application_id = vr_application_id AND i.category_id = vr_category_id AND rf.value IS NULL
		ORDER BY i.sequence_number ASC
	)
	UPDATE qa_faq_items
	SET sequence_number = rf.seq
	FROM "data" AS rf
		INNER JOIN qa_faq_items AS i
		ON i.question_id = rf.question_id
	WHERE i.application_id = vr_application_id AND i.category_id = vr_category_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

