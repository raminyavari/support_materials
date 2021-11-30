DROP FUNCTION IF EXISTS wk_p_get_paragraphs_by_ids;

CREATE OR REPLACE FUNCTION wk_p_get_paragraphs_by_ids
(
	vr_application_id	UUID,
    vr_paragraph_ids	UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wk_paragraph_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT pg.paragraph_id,
		   pg.title_id,
		   pg.title,
		   pg.body_text,
		   pg.sequence_no AS sequence_number,
		   pg.is_rich_text,
		   pg.creator_user_id,
		   pg.creation_date,
		   pg.last_modification_date,
		   pg.status,
		   vr_total_count
	FROM UNNEST(vr_paragraph_ids) AS x
		INNER JOIN wk_paragraphs AS pg
		ON pg.application_id = vr_application_id AND pg.paragraph_id = x
	ORDER BY pg.sequence_no ASC;
END;
$$ LANGUAGE plpgsql;

