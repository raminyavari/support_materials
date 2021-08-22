DROP FUNCTION IF EXISTS wk_fn_has_wiki_content;

CREATE OR REPLACE FUNCTION wk_fn_has_wiki_content
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS "p"
			ON "p".application_id = vr_application_id AND "p".title_id = tt.title_id
		WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id AND 
			tt.deleted = FALSE AND "p".deleted = FALSE AND COALESCE("p".body_text, N'') <> N'' AND
			("p".status = 'Accepted' OR "p".status = 'CitationNeeded')
		LIMIT 1
	), FALSE);
END;
$$ LANGUAGE PLPGSQL;