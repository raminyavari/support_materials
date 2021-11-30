DROP FUNCTION IF EXISTS wk_get_paragraphs;

CREATE OR REPLACE FUNCTION wk_get_paragraphs
(
	vr_application_id	UUID,
    vr_title_ids		guid_table_type[],
	vr_is_admin		 	BOOLEAN,
	vr_viewer_user_id	UUID,
	vr_deleted		 	BOOLEAN
)
RETURNS SETOF wk_paragraph_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_title_ids := ARRAY(
		SELECT DISTINCT x
		FROM UNNEST(vr_title_ids) AS x
	);

	vr_ids := ARRAY(
		SELECT pg.paragraph_id
		FROM UNNEST(vr_title_ids) AS ex
			INNER JOIN wk_paragraphs AS pg
			ON pg.title_id = ex.value
		WHERE pg.application_id = vr_application_id AND 
			(vr_is_admin = TRUE OR pg.status = 'Accepted' OR pg.status = 'CitationNeeded' OR (
				pg.status = 'Pending' AND vr_viewer_user_id IS NOT NULL AND 
				pg.creator_user_id = vr_viewer_user_id
			)) AND pg.deleted = vr_deleted
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_paragraphs_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

