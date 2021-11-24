DROP FUNCTION IF EXISTS qa_set_faq_categories_order;

CREATE OR REPLACE FUNCTION qa_set_faq_categories_order
(
	vr_application_id		UUID,
	vr_category_ids			guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_parent_id 	UUID;
	vr_ids			UUID[];
	vr_result		INTEGER;
BEGIN
	SELECT vr_parent_id = fc.parent_id
	FROM qa_faq_categories AS fc
	WHERE fc.application_id = vr_application_id AND 
		fc.category_id = (SELECT rf.value FROM UNNEST(vr_category_ids) AS rf LIMIT 1)
	LIMIT 1;
	
	vr_ids := ARRAY(
		(SELECT x.value AS "id"
		FROM UNNEST(vr_category_ids) WITH ORDINALITY AS x("value", seq)
		ORDER BY x.seq ASC)
		
		UNION ALL
		
		SELECT fc.category_id
		FROM UNNEST(vr_category_ids) AS rf
			RIGHT JOIN qa_faq_categories AS fc
			ON fc.application_id = vr_application_id AND fc.category_id = rf.value
		WHERE fc.application_id = vr_application_id AND 
			((fc.parent_id IS NULL AND vr_parent_id IS NULL) OR fc.parent_id = vr_parent_id) AND 
			rf.value IS NULL
		ORDER BY fc.sequence_number ASC
	);
	
	UPDATE qa_faq_categories
	SET sequence_number = rf.seq
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf("id", seq)
		INNER JOIN qa_faq_categories AS "c"
		ON "c".category_id = rf.id
	WHERE "c".application_id = vr_application_id AND 
		(("c".parent_id IS NULL AND vr_parent_id IS NULL) OR "c".parent_id = vr_parent_id);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

