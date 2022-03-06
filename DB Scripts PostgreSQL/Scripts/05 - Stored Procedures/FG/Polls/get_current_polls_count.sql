DROP FUNCTION IF EXISTS fg_get_current_polls_count;

CREATE OR REPLACE FUNCTION fg_get_current_polls_count
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP,
	vr_default_privacy	VARCHAR(50)
)
RETURNS TABLE (
	"count"		INTEGER,
	done_count	INTEGER
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
	SELECT	COUNT(x.poll_id)::INTEGER AS "count",
			SUM(x.done)::INTEGER AS done_count
	FROM (
			SELECT	"p".poll_id,
					MAX(CASE WHEN fi.instance_id IS NULL THEN 0 ELSE 1 END::INTEGER) AS done
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
					vr_poll_ids, 'Poll', vr_now, vr_permission_types) AS ids
				INNER JOIN fg_polls AS "p"
				ON "p".application_id = vr_application_id AND "p".poll_id = ids.id
				LEFT JOIN fg_form_instances AS fi
				ON fi.application_id = vr_application_id AND fi.owner_id = ids.id AND
					fi.director_id = vr_current_user_id AND fi.deleted = FALSE
			GROUP BY "p".poll_id
		) AS x;
END;
$$ LANGUAGE plpgsql;

