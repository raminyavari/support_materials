DROP FUNCTION IF EXISTS fg_get_form_records;

CREATE OR REPLACE FUNCTION fg_get_form_records
(
	vr_application_id		UUID,
	vr_form_id				UUID,
	vr_element_ids			guid_table_type[],
	vr_instance_ids			guid_table_type[],
	vr_owner_ids			guid_table_type[],
	vr_filters				form_filter_table_type[],
	vr_lower_boundary	 	INTEGER,
	vr_count			 	INTEGER,
	vr_sort_by_element_id	UUID,
	vr_desc			 		BOOLEAN
)
RETURNS REFCURSOR
AS
$$
BEGIN
	RETURN fg_p_get_form_records(
		vr_application_id, 
		vr_form_id, 
		ARRAY(
			SELECT x.value
			FROM UNNEST(vr_element_ids) AS x
		), 
		ARRAY(
			SELECT x.value
			FROM UNNEST(vr_instance_ids) AS x
		), 
		ARRAY(
			SELECT x.value
			FROM UNNEST(vr_owner_ids) AS x
		), 
		vr_filters, 
		vr_lower_boundary, 
		vr_count, 
		vr_sort_by_element_id, 
		vr_desc
	);
END;
$$ LANGUAGE plpgsql;

