DROP FUNCTION IF EXISTS qa_is_faq_category;

CREATE OR REPLACE FUNCTION qa_is_faq_category
(
	vr_application_id	UUID,
    vr_ids				guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT "c".category_id AS "id"
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN qa_faq_categories AS "c"
		ON "c".application_id = vr_application_id AND "c".category_id = rf.value;
END;
$$ LANGUAGE plpgsql;

