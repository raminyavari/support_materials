DROP FUNCTION IF EXISTS fg_get_polls;

CREATE OR REPLACE FUNCTION fg_get_polls
(
	vr_application_id		UUID,
	vr_is_copy_of_poll_id	UUID,
	vr_owner_id				UUID,
	vr_archive	 			BOOLEAN,
	vr_search_text	 		VARCHAR(500),
	vr_count		 		INTEGER,
	vr_lower_boundary		BIGINT
)
RETURNS SETOF fg_poll_ret_composite
AS
$$
DECLARE
	vr_ids			UUID[];
	vr_total_count	INTEGER;
BEGIN
	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY pgroonga_score("p".tableoid, "p".ctid) DESC, 
								   "p".creation_date DESC, "p".poll_id DESC) AS "row_number",
				"p".poll_id
		FROM fg_polls AS "p"
		WHERE "p".application_id = vr_application_id AND 
			"p".deleted = COALESCE(vr_archive, FALSE)::BOOLEAN AND
			(COALESCE(vr_search_text, '') = '' OR "p".name &@~ vr_search_text) AND (
				(vr_is_copy_of_poll_id IS NULL AND "p".is_copy_of_poll_id IS NULL) OR 
				(vr_is_copy_of_poll_id IS NOT NULL AND "p".is_copy_of_poll_id = vr_is_copy_of_poll_id)
			) AND (
				(vr_owner_id IS NULL AND "p".owner_id IS NULL) OR 
				(vr_owner_id IS NOT NULL AND p.owner_id = vr_owner_id)
			)
	),
	total AS
	(
		SELECT COUNT(d.poll_id) AS total_count
		FROM "data" AS d
	)
	SELECT INTO vr_ids, vr_total_count
				ARRAY(
					SELECT d.poll_id
					FROM "data" AS d
					WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
					ORDER BY d.row_number ASC
					LIMIT COALESCE(vr_count, 20)
				),
				(SELECT x.total_count::INTEGER FROM total AS x LIMIT 1);
	
	RETURN QUERY
	SELECT *
	FROM fg_p_get_polls_by_ids(vr_application_id, vr_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;

