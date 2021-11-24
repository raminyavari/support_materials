DROP FUNCTION IF EXISTS qa_get_child_faq_categories;

CREATE OR REPLACE FUNCTION qa_get_child_faq_categories
(
	vr_application_id	UUID,
    vr_parent_id		UUID,
    vr_current_user_id	UUID,
    vr_check_access	 	BOOLEAN,
    vr_default_privacy	VARCHAR(50),
    vr_now			 	TIMESTAMP
)
RETURNS TABLE (
	category_id	UUID,
	"name"		VARCHAR,
	has_child	BOOLEAN
)
AS
$$
DECLARE
	vr_permission_types	string_pair_table_type[];
BEGIN
	vr_permission_types := ARRAY(
		SELECT ROW('View', vr_default_privacy)
	);
	
	RETURN QUERY
	WITH "data" AS
	(
		SELECT	"c".category_id, 
				"c".name, 
				"c".sequence_number,
				COALESCE((
					SELECT TRUE
					FROM qa_faq_categories AS fc
					WHERE fc.application_id = vr_application_id AND 
						fc.parent_id = "c".category_id AND fc.deleted = FALSE
					LIMIT 1
				), FALSE)::BOOLEAN AS has_child
		FROM qa_faq_categories AS "c"
		WHERE "c".application_id = vr_application_id AND "c".deleted = FALSE AND
			(("c".parent_id IS NULL AND vr_parent_id IS NULL) OR ("c".parent_id = vr_parent_id))
	),
	filtered AS
	(
		SELECT d.*
		FROM "data" AS d
			LEFT JOIN prvc_fn_check_access(vr_application_id, vr_current_user_id, 
										   ARRAY(SELECT x.category_id FROM "data" AS x), 
										   'FAQCategory', vr_now, vr_permission_types) AS "a"
			ON vr_check_access = TRUE AND "a".id = d.category_id
		WHERE COALESCE(vr_check_access, FALSE)::BOOLEAN = FALSE OR "a".id IS NOT NULL
	)
	SELECT	f.category_id,
			f.name,
			f.has_child
	FROM filtered AS f
	ORDER BY f.sequence_number ASC, f.category_id ASC;
END;
$$ LANGUAGE plpgsql;

