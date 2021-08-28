DROP FUNCTION IF EXISTS cn_fn_get_parent_category_hierarchy;

CREATE OR REPLACE FUNCTION cn_fn_get_parent_category_hierarchy
(
	vr_application_id	UUID,
	vr_category_id		UUID
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
	WITH RECURSIVE "hierarchy"
 	AS 
	(
		SELECT f.category_id AS "id", f.parent_id AS parent_id, 0::INTEGER AS "level", f.name
		FROM qa_faq_categories AS f
		WHERE f.application_id = vr_application_id AND f.category_id = vr_category_id
		
		UNION ALL
		
		SELECT "c".category_id AS "id", "c".parent_id AS parent_id, "level" + 1, "c".name
		FROM qa_faq_categories AS "c"
			INNER JOIN "hierarchy" AS hr
			ON "c".category_id = hr.parent_id
		WHERE "c".application_id = vr_application_id AND 
			"c".category_id <> hr.id AND "c".deleted = FALSE
	)
	SELECT * 
	FROM "hierarchy" AS h
	ORDER BY h.level ASC;
END;
$$ LANGUAGE PLPGSQL;