DROP FUNCTION IF EXISTS cn_fn_get_child_categories_hierarchy;

CREATE OR REPLACE FUNCTION cn_fn_get_child_categories_hierarchy
(
	vr_application_id	UUID,
	vr_category_ids		UUID[]
)
RETURNS TABLE (
	category_id UUID,
	parent_id 	UUID,
	"level" 	INTEGER,
	"name" 		VARCHAR(2000)
)
AS
$$
BEGIN
	RETURN QUERY
	WITH tbl
 	AS 
	(
		SELECT "c".category_id AS "id", "c".parent_id, 0::INTEGER AS "level", "c".name
		FROM UNNEST(vr_category_ids) AS n
			INNER JOIN qa_faq_categories AS "c"
			ON "c".application_id = vr_application_id AND "c".category_id = n
	)
	SELECT * 
	FROM tbl
	
	UNION ALL
	
	SELECT "c".category_id AS "id", "c".parent_id, hr."level" + 1, "c".name
	FROM qa_faq_categories AS "c"
		INNER JOIN tbl AS hr
		ON "c".parent_id = hr.id
	WHERE "c".application_id = vr_application_id AND "c".category_id <> hr.id AND "c".deleted = FALSE;
END;
$$ LANGUAGE PLPGSQL;