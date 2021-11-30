DROP FUNCTION IF EXISTS wk_get_titles_by_ids;

CREATE OR REPLACE FUNCTION wk_get_titles_by_ids
(
	vr_application_id	UUID,
    vr_title_ids		guid_table_type[],
	vr_viewer_user_id	UUID
)
RETURNS SETOF wk_title_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_title_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_titles_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

