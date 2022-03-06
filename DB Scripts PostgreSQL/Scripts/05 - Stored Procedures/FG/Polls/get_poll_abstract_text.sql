DROP FUNCTION IF EXISTS fg_get_poll_abstract_text;

CREATE OR REPLACE FUNCTION fg_get_poll_abstract_text
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
	vr_cur		INTEGER;
	
	vr_eid 		UUID;
	vr_val 		VARCHAR;
	vr_num 		FLOAT;
	
	vr_cursor_1	REFCURSOR;
	vr_cursor_2	REFCURSOR;
BEGIN
	DROP TABLE IF EXISTS tmp_75982;	
	DROP TABLE IF EXISTS tbl_84534;

	CREATE TEMP TABLE tmp_75982 (
		seq 		SERIAL PRIMARY KEY,
		element_id 	UUID, 
		"value" 	VARCHAR, 
		"number" 	FLOAT
	);
	
	CREATE TEMP TABLE tbl_84534 (
		element_id 	UUID, 
		"value" 	VARCHAR, 
		"number" 	FLOAT
	);

	INSERT INTO tmp_75982 (element_id, "value", "number")
	SELECT ids.value, ie.text_value, ie.float_value
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND
			LTRIM(RTRIM(COALESCE(ie.text_value, ''))) <> ''
		INNER JOIN UNNEST(vr_element_ids) AS ids
		ON ids.value = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE;

	vr_cur := (SELECT MAX(x.seq) FROM tmp_75982 AS x);

	WHILE vr_cur > 0 LOOP
		vr_eid := NULL;
		vr_val := NULL;
		vr_num := NULL;

		SELECT INTO vr_eid, vr_val, vr_num 
					"t".element_id, "t".value, "t".number
		FROM tmp_75982 AS "t"
		WHERE "t".seq = vr_cur
		LIMIT 1;
		
		INSERT INTO tbl_84534 (element_id, "value", "number")
		SELECT vr_eid, LTRIM(RTRIM(rf)), vr_num
		FROM UNNEST(STRING_TO_ARRAY(COALESCE(vr_val, ''), '~')) AS rf
		WHERE LTRIM(RTRIM(rf)) <> '';
		
		vr_cur := vr_cur - 1;
	END LOOP;

	OPEN vr_cursor_1 FOR
	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER(PARTITION BY x.element_id ORDER BY x.count DESC, x.value DESC) AS "row_number",
				x.*
		FROM (
				SELECT 	"t".element_id, 
						"t".value, 
						COUNT("t".element_id) AS "count"
				FROM tbl_84534 AS "t"
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
			MIN("t".number) AS "min", 
			MAX("t".number) AS "max", 
			AVG("t".number) AS "avg", 
			COALESCE(VARIANCE("t".number), 0) AS var, 
			COALESCE(STDDEV("t".number), 0) AS st_dev
	FROM tbl_84534 AS "t"
	WHERE "t".number IS NOT NULL
	GROUP BY "t".element_id;
	RETURN NEXT vr_cursor_2;
END;
$$ LANGUAGE plpgsql;

