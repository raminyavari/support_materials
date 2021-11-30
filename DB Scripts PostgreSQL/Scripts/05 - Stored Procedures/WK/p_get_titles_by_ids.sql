DROP FUNCTION IF EXISTS wk_p_get_titles_by_ids;

CREATE OR REPLACE FUNCTION wk_p_get_titles_by_ids
(
	vr_application_id	UUID,
    vr_title_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wk_title_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT tt.title_id,
		   tt.owner_id,
		   tt.title,
		   tt.sequence_no AS sequence_number,
		   tt.creator_user_id,
		   tt.creation_date,
		   tt.last_modification_date,
		   tt.status,
		   vr_total_count
	FROM UNNEST(vr_title_ids) AS x
		INNER JOIN wk_titles AS tt
		ON tt.application_id = vr_application_id AND tt.title_id = x
	ORDER BY tt.sequence_no ASC;
END;
$$ LANGUAGE plpgsql;

