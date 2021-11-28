DROP FUNCTION IF EXISTS qa_search_questions;

CREATE OR REPLACE FUNCTION qa_search_questions
(
	vr_application_id	UUID,
    vr_search_text	 	VARCHAR(512),
    vr_user_id			UUID,
    vr_count		 	INTEGER,
    vr_min_id			UUID
)
RETURNS SETOF qa_question_ret_composite
AS
$$
DECLARE
	vr_question_ids	UUID[];
BEGIN
	vr_search_text := gfn_verify_string(vr_search_text);
	
	WITH "data" AS
	(
		SELECT 	ROW_NUMBER() OVER (ORDER BY pgroonga_score(q.tableoid, q.ctid) DESC, q.question_id ASC)::INTEGER AS seq,
				q.question_id 
		FROM qa_questions AS q
		WHERE q.application_id = vr_application_id AND 
			q.publication_date IS NOT NULL AND q.deleted = FALSE AND
			(COALESCE(vr_search_text, '') = '' OR q.title &@~ vr_search_text OR
				q.description &@~ vr_search_text)
	),
	loc AS 
	(
		SELECT COALESCE((
			SELECT d.seq 
			FROM "data" AS d
			WHERE vr_min_id IS NOT NULL AND d.question_id = vr_min_id
			ORDER BY d.seq ASC
			LIMIT 1
		), 0)::INTEGER AS "value"
	)
	SELECT vr_question_ids = ARRAY(
		SELECT d.question_id 
		FROM "data" AS d
		WHERE d.seq > vr_loc
		ORDER BY d.seq ASC
		LIMIT COALESCE(vr_count, 1000000)
	);
	
	RETURN QUERY
	SELECT *
	FROM qa_p_get_questions_by_ids(vr_application_id, vr_question_ids, vr_user_id);
END;
$$ LANGUAGE plpgsql;

