DROP FUNCTION IF EXISTS qa_add_question_to_faq_categories;

CREATE OR REPLACE FUNCTION qa_add_question_to_faq_categories
(
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_category_ids		guid_table_type[],
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids		UUID[];
	vr_seq_no	INTEGER;
BEGIN
	WITH "data" AS 
	(
		SELECT DISTINCT c.value AS category_id
		FROM UNNEST(vr_category_ids) AS "c"
			LEFT JOIN qa_faq_items AS i
			ON i.application_id = vr_application_id AND 
				i.category_id = "c".value AND i.question_id = vr_question_id
		WHERE i.category_id IS NULL OR i.deleted = TRUE
	)
	SELECT vr_ids = ARRAY(
		SELECT d.category_id
		FROM "data" AS d
			LEFT JOIN qa_faq_items AS i
			ON i.application_id = vr_application_id AND i.category_id = d.category_id
		GROUP BY d.category_id
		ORDER BY COALESCE(MAX(i.sequence_number), 0)::INTEGER + 1::INTEGER ASC
	);
	
	UPDATE qa_faq_items
	SET deleted = FALSE,
		sequence_number = x.seq,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = x.id AND i.question_id = vr_question_id;
			
	INSERT INTO qa_faq_items (
		application_id,
		category_id,
		question_id,
		sequence_number,
		creator_user_id,
		creation_date,
		deleted
	) 
	SELECT	vr_application_id, 
			x.id, 
			vr_question_id, 
			x.seq, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_ids) WITH ORDINALITY AS x("id", seq)
		LEFT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = x.id AND i.question_id = vr_question_id
	WHERE i.category_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

