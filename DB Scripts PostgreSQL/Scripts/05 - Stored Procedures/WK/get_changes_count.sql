DROP FUNCTION IF EXISTS wk_get_changes_count;

CREATE OR REPLACE FUNCTION wk_get_changes_count
(
	vr_application_id	UUID,
    vr_paragraph_ids	guid_table_type[],
	vr_applied			BOOLEAN
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
			COUNT("c".change_id)::INTEGER AS "count"
	FROM UNNEST(vr_paragraph_ids) AS x
		LEFT JOIN wk_changes AS "c"
		ON "c".application_id = vr_application_id AND "c".paragraph_id = x.value
	WHERE ("c".status = 'Accepted' OR "c".status = 'CitationNeeded') AND 
		(vr_applied IS NULL OR "c".applied = vr_applied) AND "c".deleted = FALSE
	GROUP BY x.value;
END;
$$ LANGUAGE plpgsql;

