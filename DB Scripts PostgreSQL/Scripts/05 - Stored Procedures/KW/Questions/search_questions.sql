DROP FUNCTION IF EXISTS kw_search_questions;

CREATE OR REPLACE FUNCTION kw_search_questions
(
	vr_application_id	UUID,
	vr_search_text		VARCHAR(1000),
	vr_count			INTEGER
)
RETURNS SETOF VARCHAR
AS
$$
BEGIN
	vr_search_text := gfn_verify_string(vr_search_text);
	
	IF vr_count IS NULL OR vr_count <= 0 THEN
		vr_count := 1000000;
	END IF;
	
	RETURN QUERY
	SELECT q.title AS "value"
	FROM kw_questions AS q
	WHERE q.application_id = vr_application_id AND q.deleted = FALSE AND
		(COALESCE(vr_search_text, '') = '' OR q.title &@~ vr_search_text)
	ORDER BY pgroonga_score(q.tableoid, q.ctid) DESC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;

