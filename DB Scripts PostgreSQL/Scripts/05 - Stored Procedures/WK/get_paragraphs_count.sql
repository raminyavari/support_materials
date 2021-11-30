DROP FUNCTION IF EXISTS wk_get_paragraphs_count;

CREATE OR REPLACE FUNCTION wk_get_paragraphs_count
(
	vr_application_id	UUID,
    vr_title_ids		guid_table_type[],
	vr_is_admin	 		BOOLEAN,
	vr_current_user_id	UUID,
	vr_removed	 		BOOLEAN
)
RETURNS TABLE (
	"id"	UUID,
	"count"	INTEGER
)
AS
$$
BEGIN	
	RETURN QUERY
	SELECT 	x.value AS "id", 
			COUNT("p".paragraph_id)::INTEGER AS "count"
	FROM UNNEST(vr_title_ids) AS x
		LEFT JOIN wk_paragraphs AS "p"
		ON "p".application_id = vr_application_id AND "p".title_id = x.value
	WHERE (vr_is_admin = TRUE OR "p".status = 'Accepted' OR "p".status = 'CitationNeeded' OR (
			"p".status = 'Pending' AND vr_current_user_id IS NOT NULL AND 
			"p".creator_user_id = vr_current_user_id
		)) AND (vr_removed IS NULL OR p.deleted = vr_removed)
	GROUP BY x.value;
END;
$$ LANGUAGE plpgsql;

