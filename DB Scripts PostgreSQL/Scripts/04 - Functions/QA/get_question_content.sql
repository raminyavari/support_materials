DROP FUNCTION IF EXISTS cn_fn_get_question_content;

CREATE OR REPLACE FUNCTION cn_fn_get_question_content
(
	vr_application_id	UUID,
	vr_question_id		UUID
)
RETURNS VARCHAR
AS
$$
DECLARE
	vr_ret	VARCHAR;
BEGIN
	WITH partitioned AS 
	(
		SELECT	an.answer_id,
				SUBSTRING(COALESCE(an.answer_body, N''), 1, 4000)::VARCHAR(4000) AS "content",
				ROW_NUMBER() OVER (PARTITION BY an.question_id ORDER BY an.answer_id) AS "number",
				COUNT(*) OVER (PARTITION BY an.question_id) AS "count"
		FROM qa_answers AS an
		WHERE an.application_id = vr_application_id AND
			an.question_id = vr_question_id AND an.deleted = FALSE
	),
	fetched AS 
	(
		SELECT "p".answer_id, "p".content AS full_content, "p".content, "p".number, "p".count 
		FROM partitioned AS "p"
		WHERE "p".number = 1

		UNION ALL

		SELECT	"p".answer_id, "c".full_content || ' ' || "p".content, "p".content, "p".number, "p".count
		FROM partitioned AS "p"
			INNER JOIN fetched AS "c" 
			ON "p".answer_id = "c".answer_id AND "p".number = "c".number + 1
		WHERE "p".number <= 95
	)
	SELECT vr_ret = f.full_content
	FROM fetched AS f
	WHERE f.number = (CASE WHEN f.count > 90 THEN 90 ELSE f.count END)
	LIMIT 1;
	
	RETURN vr_ret;
END;
$$ LANGUAGE PLPGSQL;