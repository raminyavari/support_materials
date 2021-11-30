DROP FUNCTION IF EXISTS wk_has_paragraph;

CREATE OR REPLACE FUNCTION wk_has_paragraph
(
	vr_application_id		UUID,
    vr_title_or_owner_id	UUID,
	vr_viewer_user_id		UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	IF EXISTS (
		SELECT 1 
		FROM wk_titles AS tt
		WHERE tt.application_id = vr_application_id AND tt.title_id = vr_title_or_owner_id
		LIMIT 1
	) THEN
		RETURN COALESCE((
			SELECT TRUE
			FROM wk_paragraphs AS "p"
			WHERE "p".application_id = vr_application_id AND "p".title_id = vr_title_or_owner_id AND
				(vr_viewer_user_id IS NULL OR "p".status = 'Accepted' OR 
				"p".status = 'CitationNeeded' OR "p".creator_user_id = vr_viewer_user_id) AND "p".deleted = FALSE
			LIMIT 1
		), FALSE)::BOOLEAN;
	ELSE
		RETURN COALESCE((
			SELECT TRUE
			FROM wk_titles AS tt
				INNER JOIN wk_paragraphs AS pg
				ON pg.application_id = vr_application_id AND pg.title_id = tt.title_id
			WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_title_or_owner_id AND
				(vr_viewer_user_id IS NULL OR pg.status = 'Accepted' OR 
				pg.status = 'CitationNeeded' OR pg.creator_user_id = vr_viewer_user_id) AND pg.deleted = FALSE
			LIMIT 1
		), FALSE)::BOOLEAN;
	END IF;
END;
$$ LANGUAGE plpgsql;

