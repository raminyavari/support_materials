DROP FUNCTION IF EXISTS prvc_get_confidentiality_level_user_ids;

CREATE OR REPLACE FUNCTION prvc_get_confidentiality_level_user_ids
(
	vr_application_id		UUID,
	vr_confidentiality_id	UUID,
	vr_search_text			VARCHAR(500),
	vr_count				INTEGER,
	vr_lower_boundary		BIGINT
)
RETURNS TABLE (
	user_id		UUID,
	total_count	INTEGER
)
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(vr_count, 0) <= 0 THEN
		vr_count := 1000000;
	END IF;
	
	RETURN QUERY
	WITH "data" AS 
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY 
								   pgroonga_score(usr.tableoid, usr.ctid)::FLOAT DESC,
								   usr.user_id DESC
								  ) AS "row_number",
				usr.user_id
		FROM prvc_view_confidentialities AS "c"
			INNER JOIN usr_profile AS usr
			ON usr.application_id = vr_application_id AND usr.user_id = "c".object_id AND
				(
					COALESCE(vr_search_text, '') = '' OR usr.first_name &@~ vr_search_text OR
					usr.last_name &@~ vr_search_text OR usr.username &@~ vr_search_text
				)
		WHERE "c".application_id = vr_application_id AND 
			"c".confidentiality_id = vr_confidentiality_id
	),
	total AS 
	(
		SELECT COUNT(d.user_id)::INTEGER AS total_count
		FROM "data" AS d
	)
	SELECT	r.user_id,
			"t".total_count
	FROM "data" AS d
		CROSS JOIN total AS "t"
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;

