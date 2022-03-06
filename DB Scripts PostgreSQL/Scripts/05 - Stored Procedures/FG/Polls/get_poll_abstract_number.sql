DROP FUNCTION IF EXISTS fg_get_poll_abstract_number;

CREATE OR REPLACE FUNCTION fg_get_poll_abstract_number
(
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_element_ids		guid_table_type[],
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_cursor_1	REFCURSOR;
	vr_cursor_2	REFCURSOR;
BEGIN
	DROP TABLE IF EXISTS tbl_84535;

	CREATE TEMP TABLE tbl_84535 (
		element_id 	UUID, 
		"value" 	FLOAT
	);
	
	INSERT INTO tbl_84535 (element_id, "value")
	SELECT ids.value, ie.float_value
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND ie.float_value IS NOT NULL
		INNER JOIN UNNEST(vr_element_ids) AS ids
		ON ids.value = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE;

	OPEN vr_cursor_1 FOR
	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count DESC, x.value DESC) AS "row_number",
				x.*
		FROM (
				SELECT 	"t".element_id, 
						"t".value, 
						COUNT("t".element_id) AS "count"
				FROM tbl_84535 AS "t"
				GROUP BY "t".element_id, "t".value
			) AS x
	),
	total AS
	(
		SELECT COUNT(d.element_id) AS total_count
		FROM "data" AS d
	)
	SELECT 	"t".total_count::INTEGER AS total_values_count,
			d.element_id,
			d.value,
			d.count
	FROM "data" AS d
		CROSS JOIN total AS "t"
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT COALESCE(vr_count, 5);
	RETURN NEXT vr_cursor_1;
	
	OPEN vr_cursor_2 FOR
	SELECT	"t".element_id, 
			MIN("t".value) AS "min", 
			MAX("t".value) AS "max", 
			AVG("t".value) AS "avg", 
			COALESCE(VARIANCE("t".value), 0) AS var, 
			COALESCE(STDDEV("t".value), 0) AS st_dev
	FROM tbl_84535 AS "t"
	GROUP BY "t".element_id;
	RETURN NEXT vr_cursor_2;
END;
$$ LANGUAGE plpgsql;

