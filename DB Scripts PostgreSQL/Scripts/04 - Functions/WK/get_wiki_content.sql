DROP FUNCTION IF EXISTS wk_fn_get_wiki_content;

CREATE OR REPLACE FUNCTION wk_fn_get_wiki_content
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS VARCHAR
AS
$$
DECLARE 
	vr_ret	VARCHAR;
BEGIN
	WITH RECURSIVE partitioned AS 
	(
		SELECT	tt.owner_id,
				N' <h1>' + COALESCE(tt.title, N'') + N'</h1> ' + 
				N' <h2>' + COALESCE("p".title, N'') + N'</h2> ' + 
				SUBSTRING(COALESCE("p".body_text, N''), 1, 4000)::VARCHAR(4000) AS "content",
				ROW_NUMBER() OVER (PARTITION BY tt.owner_id ORDER BY "p".paragraph_id) AS "number",
				COUNT(*) OVER (PARTITION BY tt.owner_id) AS "count"
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS "p"
			ON "p".application_id = vr_application_id AND "p".title_id = tt.title_id
		WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id AND 
			tt.deleted = FALSE AND "p".deleted = FALSE AND COALESCE("p".body_text, N'') <> N'' AND
			("p".status = 'Accepted' OR "p".status = 'CitationNeeded')
	),
	fetched AS 
	(
		SELECT	"p".owner_id, "p".content AS full_content, "p".content, "p".number, "p".count 
		FROM partitioned AS "p"
		WHERE "p".number = 1

		UNION ALL

		SELECT	"p".owner_id, "c".full_content + ' ' + "p".content, "p".content, "p".number, "p".count
		FROM partitioned AS "p"
			INNER JOIN fetched AS "c" 
			ON "p".owner_id = "c".owner_id AND "p".number = "c".number + 1
		WHERE "p".number <= 95
	)
	SELECT vr_ret = f.full_content
	FROM fetched AS f
	WHERE f.number = (CASE WHEN f.count > 90 THEN 90 ELSE f.count END)
	LIMIT 1;
	
	RETURN vr_ret;
END;
$$ LANGUAGE PLPGSQL;