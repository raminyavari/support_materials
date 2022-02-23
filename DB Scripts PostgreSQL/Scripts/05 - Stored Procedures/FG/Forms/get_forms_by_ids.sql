DROP FUNCTION IF EXISTS fg_get_forms_by_ids;

CREATE OR REPLACE FUNCTION fg_get_forms_by_ids
(
	vr_application_id	UUID,
    vr_form_ids			guid_table_type[]
)
RETURNS SETOF fg_form_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM fg_p_get_forms_by_ids(vr_application_id, ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_form_ids) AS x
	));
END;
$$ LANGUAGE plpgsql;

