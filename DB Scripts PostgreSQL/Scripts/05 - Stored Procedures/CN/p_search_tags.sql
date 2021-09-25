DROP FUNCTION IF EXISTS cn_p_search_tags;

CREATE OR REPLACE FUNCTION cn_p_search_tags
(
	vr_application_id	UUID,
	vr_search_text	 	VARCHAR(1000),
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	tag_id		UUID,
	tag			VARCHAR,
	is_approved	BOOLEAN,
	calls_count	INTEGER
)
AS
$$
BEGIN
	vr_search_text := gfn_verify_string(vr_search_text);
	
	IF vr_count IS NULL OR vr_count <= 0 THEN
		vr_count := 1000;
	END IF;
	
	RETURN QUERY
	WITH "data" AS (
		SELECT	ROW_NUMBER() OVER (ORDER BY pgroonga_score(tg.tableoid, tg.ctid) DESC, tg.tag ASC) AS "row_number",
				tg.tag_id, 
				tg.tag, 
				tg.is_approved, 
				tg.calls_count
		FROM cn_tags AS tg
		WHERE tg.application_id = vr_application_id AND 
			tg.deleted = FALSE AND COALESCE(tg.tag, '') <> '' AND
			(COALESCE(vr_search_text, '') = '' OR tg.tag &@~ vr_search_text)
	)
	SELECT d.tag_id, d.tag, d.is_approved, d.calls_count
	FROM "data" AS d
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;
