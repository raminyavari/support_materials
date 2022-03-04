DROP FUNCTION IF EXISTS fg_get_forms;

CREATE OR REPLACE FUNCTION fg_get_forms
(
	vr_application_id	UUID,
	vr_search_text	 	VARCHAR(1000),
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER,
	vr_has_name	 		BOOLEAN,
	vr_archive	 		BOOLEAN
)
RETURNS SETOF fg_form_ret_composite
AS
$$
DECLARE
	vr_ids			UUID[];
	vr_total_count	INTEGER;
BEGIN
	vr_archive := COALESCE(vr_archive, FALSE)::BOOLEAN;

	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY pgroonga_score(f.tableoid, f.ctid) DESC, f.form_id ASC) AS "row_number",
				f.form_id 
		FROM fg_extended_forms AS f
		WHERE f.application_id = vr_application_id AND f.deleted = vr_archive AND
			(COALESCE(vr_search_text, '') = '' OR f.title &@~ vr_search_text) AND
			(
				vr_has_name IS NULL OR 
				(vr_has_name = FALSE AND COALESCE(f.name, '') = '') OR 
				(vr_has_name = TRUE AND COALESCE(f.name, '') <> '')
			)
	),
	total AS
	(
		SELECT COUNT(d.form_id) AS total_count
		FROM "data" AS d
	)
	SELECT INTO	vr_total_count, vr_ids
			COALESCE((SELECT "t".total_count FROM total AS "t" LIMIT 1))::INTEGER,
			 ARRAY(
				SELECT d.form_id
				FROM "data" AS d
				WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
				ORDER BY d.row_number ASC
				LIMIT COALESCE(vr_count, 1000000)
			);
	
	RETURN QUERY
	SELECT *
	FROM fg_p_get_forms_by_ids(vr_application_id, vr_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;

