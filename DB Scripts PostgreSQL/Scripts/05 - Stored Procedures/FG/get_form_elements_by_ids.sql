DROP FUNCTION IF EXISTS fg_get_form_elements_by_ids;

CREATE OR REPLACE FUNCTION fg_get_form_elements_by_ids
(
	vr_application_id	UUID,
	vr_element_ids		guid_table_type[]
)
RETURNS SETOF fg_form_element_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM fg_p_get_form_elements(
		vr_application_id, 
		ARRAY(
			SELECT x.value
			FROM UNNEST(vr_element_ids) AS x
		)
	);
END;
$$ LANGUAGE plpgsql;

