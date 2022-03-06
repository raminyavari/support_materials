DROP FUNCTION IF EXISTS fg_get_current_polls;

CREATE OR REPLACE FUNCTION fg_get_current_polls
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP,
	vr_default_privacy	VARCHAR(50),
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	"id"		UUID, 
	"value"		BOOLEAN,
	total_count	INTEGER
)
AS
$$
DECLARE
	vr_poll_ids			UUID[];
	vr_permission_types string_pair_table_type[];
BEGIN
	vr_poll_ids := ARRAY(
		SELECT "p".poll_id
		FROM fg_polls AS "p"
		WHERE "p".application_id = vr_application_id AND 
			"p".is_copy_of_poll_id IS NOT NULL AND "p".owner_id IS NULL AND "p".deleted = FALSE AND 
			("p".begin_date IS NOT NULL OR "p".finish_date IS NOT NULL) AND
			("p".begin_date IS NULL OR "p".begin_date <= vr_now) AND
			("p".finish_date IS NULL OR "p".finish_date >= vr_now)
	);
	
	vr_permission_types := ARRAY(
		SELECT ROW('View', vr_default_privacy)
	);
	
	RETURN QUERY
	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER(ORDER BY MAX("p".begin_date) DESC, MAX("p".finish_date) ASC) AS "row_number",
				"p".poll_id AS "id", 
				CASE WHEN COUNT(fi.instance_id) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS done
		FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_poll_ids, 'Poll', vr_now, vr_permission_types) AS ids
			INNER JOIN fg_polls AS "p"
			ON "p".application_id = vr_application_id AND "p".poll_id = ids.id
			LEFT JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.owner_id = ids.id AND
				fi.director_id = vr_current_user_id AND fi.deleted = FALSE
		GROUP BY "p".poll_id
	),
	total AS
	(
		SELECT COUNT(d.id)::INTEGER AS total_count
		FROM "data" AS d
	)
	SELECT 	d.id, 
			d.done AS "value",
			"t".total_count
	FROM "data" AS d
		CROSS JOIN total AS "t"
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT COALESCE(vr_count, 20);
END;
$$ LANGUAGE plpgsql;

