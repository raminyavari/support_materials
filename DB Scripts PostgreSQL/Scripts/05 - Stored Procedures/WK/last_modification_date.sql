DROP FUNCTION IF EXISTS wk_last_modification_date;

CREATE OR REPLACE FUNCTION wk_last_modification_date
(
	vr_application_id	UUID,
    vr_owner_id			UUID
)
RETURNS TIMESTAMP
AS
$$
BEGIN	
	RETURN (
		SELECT MAX(pg.creation_date)
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS pg
			ON pg.application_id = vr_application_id AND pg.title_id = tt.title_id AND
				(pg.status = 'Accepted' OR pg.status = 'CitationNeeded')
		WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id
	);
END;
$$ LANGUAGE plpgsql;

