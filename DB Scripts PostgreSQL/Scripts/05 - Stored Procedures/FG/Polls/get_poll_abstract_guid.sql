DROP FUNCTION IF EXISTS fg_get_poll_abstract_guid;

CREATE OR REPLACE FUNCTION fg_get_poll_abstract_guid
(
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_element_ids		guid_table_type[],
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	total_values_count	INTEGER,
	element_id			UUID,
	"value"				UUID,
	"count"				INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS
	(
		SELECT 	ids.value AS element_id, 
				s.selected_id AS "value"
		FROM fg_form_instances AS fi
			INNER JOIN fg_instance_elements AS ie
			ON ie.application_id = vr_application_id AND 
				ie.instance_id = fi.instance_id AND ie.deleted = FALSE
			INNER JOIN UNNEST(vr_element_ids) AS ids
			ON ids.value = ie.ref_element_id
			INNER JOIN fg_selected_items AS s
			ON s.application_id = vr_application_id AND s.element_id = ie.element_id AND s.deleted = FALSE
		WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE
	),
	new_data AS
	(
		SELECT	ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count DESC, x.value DESC) AS "row_number",
				x.element_id,
				x.value,
				x.count
		FROM (
				SELECT 	d.element_id, 
						d.value, 
						COUNT(d.element_id)::INTEGER AS "count"
				FROM "data" AS d
				GROUP BY d.element_id, d.value
			) AS x
	),
	total AS
	(
		SELECT COUNT(d.element_id) AS total_count
		FROM new_data AS d
	)
	SELECT 	"t".total_count::INTEGER AS total_values_count,
			d.element_id,
			d.value,
			d.count
	FROM new_data AS d
		CROSS JOIN total AS "t"
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT COALESCE(vr_count, 5);
END;
$$ LANGUAGE plpgsql;

