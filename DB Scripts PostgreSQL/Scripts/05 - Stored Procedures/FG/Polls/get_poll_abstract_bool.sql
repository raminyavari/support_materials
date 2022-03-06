DROP FUNCTION IF EXISTS fg_get_poll_abstract_bool;

CREATE OR REPLACE FUNCTION fg_get_poll_abstract_bool
(
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_element_ids		guid_table_type[]
)
RETURNS TABLE (
	total_values_count	INTEGER,
	element_id			UUID,
	"value"				BOOLEAN,
	"count"				INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS
	(
		SELECT 	ids.value AS element_id, 
				ie.bit_value AS "value"
		FROM fg_form_instances AS fi
			INNER JOIN fg_instance_elements AS ie
			ON ie.application_id = vr_application_id AND 
				ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND ie.bit_value IS NOT NULL
			INNER JOIN UNNEST(vr_element_ids) AS ids
			ON ids.value = ie.ref_element_id
		WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE
	)
	SELECT 	NULL::INTEGER AS total_values_count,
			d.element_id, 
			d.value, 
			COUNT(d.element_id)::INTEGER AS "count"
	FROM "data" AS d
	GROUP BY d.element_id, d.value;
END;
$$ LANGUAGE plpgsql;

