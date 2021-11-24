DROP FUNCTION IF EXISTS qa_move_faq_categories;

CREATE OR REPLACE FUNCTION qa_move_faq_categories
(
	vr_application_id	UUID,
    vr_category_ids		guid_table_type[],
	vr_new_parent_id	UUID,
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM qa_fn_get_parent_category_hierarchy(vr_application_id, vr_new_parent_id) AS "p"
			INNER JOIN UNNEST(vr_category_ids) AS "c"
			ON "c".value = "p".category_id
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'CannotTransferToChilds');
		RETURN -1::INTEGER;
	END IF;
	
	UPDATE qa_faq_categories
	SET parent_id = vr_new_parent_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_category_ids) AS rf
		INNER JOIN qa_faq_categories AS "c"
		ON "c".category_id = rf.value
	WHERE "c".application_id = vr_application_id AND 
		(vr_new_parent_id IS NULL OR "c".category_id <> vr_new_parent_id);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

