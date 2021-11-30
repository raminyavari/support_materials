DROP FUNCTION IF EXISTS wk_get_paragraphs_by_ids;

CREATE OR REPLACE FUNCTION wk_get_paragraphs_by_ids
(
	vr_application_id	UUID,
    vr_paragraph_ids	guid_table_type[],
	vr_viewer_user_id	UUID
)
RETURNS SETOF wk_paragraph_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_paragraph_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_paragraphs_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

