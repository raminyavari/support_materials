DROP FUNCTION IF EXISTS wk_get_changed_wiki_owner_ids;

CREATE OR REPLACE FUNCTION wk_get_changed_wiki_owner_ids
(
	vr_application_id	UUID,
    vr_owner_ids		guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_creator_id 	UUID; 
	vr_modifier_id	UUID;
BEGIN
	vr_owner_ids := ARRAY(
		SELECT DISTINCT x
		FROM UNNEST(vr_owner_ids) AS x
	);
	
	RETURN QUERY
	SELECT DISTINCT x.value AS "id" 
	FROM UNNEST(vr_owner_ids) AS x 
		INNER JOIN wk_titles AS tt
		ON tt.application_id = vr_application_id AND tt.owner_id = x.value AND tt.deleted = FALSE
		INNER JOIN wk_paragraphs AS pg
		ON pg.application_id = vr_application_id AND pg.title_id = tt.title_id AND pg.deleted = FALSE
		INNER JOIN wk_changes AS ch
		ON ch.application_id = vr_application_id AND ch.paragraph_id = pg.paragraph_id AND
			ch.status = 'Pending' AND ch.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

