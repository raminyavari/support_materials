DROP FUNCTION IF EXISTS wk_get_changes_by_ids;

CREATE OR REPLACE FUNCTION wk_get_changes_by_ids
(
	vr_application_id	UUID,
    vr_change_ids		guid_table_type[]
)
RETURNS SETOF wk_change_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_change_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_changes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

