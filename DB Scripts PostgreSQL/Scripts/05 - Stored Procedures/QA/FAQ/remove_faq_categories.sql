DROP FUNCTION IF EXISTS qa_remove_faq_categories;

CREATE OR REPLACE FUNCTION qa_remove_faq_categories
(
	vr_application_id	UUID,
	vr_category_ids		guid_table_type[],
	vr_remove_hierarchy BOOLEAN,
    vr_current_user_id	UUID,
    vr_now			 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(vr_remove_hierarchy, FALSE)::BOOLEAN = FALSE THEN
		UPDATE qa_faq_categories
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM UNNEST(vr_category_ids) AS rf
			INNER JOIN qa_faq_categories AS "c"
			ON "c".category_id = rf.value
		WHERE "c".application_id = vr_application_id AND "c".deleted = FALSE;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
			
		UPDATE qa_faq_categories AS fc
		SET parent_id = NULL
		WHERE fc.application_id = vr_application_id AND 
			fc.parent_id IN (SELECT x.value FROM UNNEST(vr_category_ids) AS x);
		
		RETURN vr_result;
	ELSE
		UPDATE qa_faq_categories
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM qa_fn_get_child_categories_hierarchy(vr_application_id, 
												  ARRAY(
													  SELECT y.value
													  FROM UNNEST(vr_category_ids) AS y
												  )) AS rf
			INNER JOIN qa_faq_categories AS "c"
			ON "c".category_id = rf.category_id
		WHERE "c".application_id = vr_application_id;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;

		RETURN vr_result;
	END IF;
END;
$$ LANGUAGE plpgsql;

