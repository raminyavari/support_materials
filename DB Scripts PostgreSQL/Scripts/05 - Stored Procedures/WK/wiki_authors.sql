DROP FUNCTION IF EXISTS wk_wiki_authors;

CREATE OR REPLACE FUNCTION wk_wiki_authors
(
	vr_application_id	UUID,
    vr_owner_id			UUID
)
RETURNS TABLE (
	"id"	UUID,
	"count"	INTEGER
)
AS
$$
BEGIN	
	RETURN QUERY
	SELECT 	ch.user_id AS "id", 
			COUNT(ch.change_id)::INTEGER AS "count"
	FROM wk_titles AS tt
		INNER JOIN wk_paragraphs AS pg
		ON pg.application_id = vr_application_id AND pg.title_id = tt.title_id AND
			(pg.status = 'Accepted' OR pg.status = 'CitationNeeded')
		INNER JOIN wk_changes AS ch
		ON ch.application_id = vr_application_id AND 
			ch.paragraph_id = pg.paragraph_id AND ch.applied = TRUE AND ch.deleted = FALSE
	WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id AND tt.deleted = FALSE
	GROUP BY ch.user_id
	ORDER BY COUNT(ch.change_id) DESC;
END;
$$ LANGUAGE plpgsql;

