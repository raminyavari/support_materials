DROP FUNCTION IF EXISTS qa_add_faq_items;

CREATE OR REPLACE FUNCTION qa_add_faq_items
(
	vr_application_id	UUID,
    vr_category_id		UUID,
    vr_question_ids		guid_table_type[],
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
	vr_ids := ARRAY(
		SELECT DISTINCT ref.value
		FROM UNNEST(vr_question_ids) AS rf
			LEFT JOIN qa_faq_items AS i
			ON i.application_id = vr_application_id AND 
				i.category_id = vr_category_id AND i.question_id = rf.value
		WHERE i.question_id IS NULL OR i.deleted = TRUE
	);
	
	vr_seq_no := COALESCE((
		SELECT MAX(i.sequence_number) 
		FROM qa_faq_items AS i
		WHERE i.application_id = vr_application_id AND i.category_id = vr_category_id
	), 0)::INTEGER;
	
	UPDATE vr_question_ids
	SET deleted = FALSE,
		sequence_number = x.seq + vr_seq_no,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = vr_category_id AND i.question_id = x.id;
			
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
			vr_category_id, 
			x.id, 
			x.seq + vr_seq_no, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_ids) AS x
		LEFT JOIN qa_faq_items AS i
		ON i.application_id = vr_application_id AND 
			i.category_id = vr_category_id AND i.question_id = x.id
	WHERE i.question_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

