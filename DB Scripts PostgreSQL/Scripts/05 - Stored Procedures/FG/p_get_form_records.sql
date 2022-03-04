DROP FUNCTION IF EXISTS fg_p_get_form_records;

CREATE OR REPLACE FUNCTION fg_p_get_form_records
(
	vr_application_id		UUID,
	vr_form_id				UUID,
	vr_element_ids			UUID[],
	vr_instance_ids			UUID[],
	vr_owner_ids			UUID[],
	vr_filters				form_filter_table_type[],
	vr_lower_boundary	 	INTEGER,
	vr_count			 	INTEGER,
	vr_sort_by_element_id	UUID,
	vr_desc			 		BOOLEAN
)
RETURNS REFCURSOR
AS
$$
DECLARE
	vr_has_owner		BOOLEAN;
	vr_elem_ids 		UUID[];
	vr_upper_boundary 	INTEGER;
	vr_instances_count 	INTEGER DEFAULT 0;
	vr_str_sbe_id 		VARCHAR(100); 
	vr_str_form_id 		VARCHAR(100);
	vr_str_lb 			VARCHAR(100);
	vr_str_ub 			VARCHAR(100);
	vr_cur_instance_ids UUID[];
	vr_batch_size 		INTEGER DEFAULT 1000;
	vr_lower 			INTEGER DEFAULT 0;
	vr_proc				VARCHAR;
	vr_cursor			REFCURSOR;
BEGIN
	-- Preparing
	
	DROP TABLE IF EXISTS owners_98239;
	
	CREATE TEMP TABLE owners_98239 ("value" UUID primary key);
	
	INSERT INTO owners_98239 ("value") 
	SELECT UNNEST(vr_owner_ids);
	
	vr_has_owner := CASE WHEN COALESCE(ARRAY_LENGTH(vr_owner_ids, 1), 0) > 0 THEN TRUE ELSE FALSE END;

	vr_elem_ids := ARRAY(
		SELECT efe.element_id
		FROM UNNEST(vr_element_ids) AS e
			INNER JOIN fg_extended_form_elements AS efe
			ON efe.application_id = vr_application_id AND efe.element_id = e
		WHERE efe.form_id = vr_form_id
		ORDER BY efe.sequence_number ASC
	);
	
	IF COALESCE(ARRAY_LENGTH(vr_elem_ids, 1), 0) = 0 THEN
		vr_elem_ids := ARRAY(
			SELECT e.element_id
			FROM fg_extended_form_elements AS e
			WHERE e.application_id = vr_application_id AND 
				e.form_id = vr_form_id AND e.deleted = FALSE
			ORDER BY e.sequence_number ASC
		);
	END IF;
	
	IF vr_sort_by_element_id IS NULL THEN 
		vr_sort_by_element_id := (
			SELECT x 
			FROM UNNEST(vr_elem_ids) AS x 
			LIMIT 1
		);
	END IF;
	
	IF vr_count IS NULL THEN 
		vr_count := 10000;
	END IF;
	
	IF COALESCE(vr_lower_boundary, 0) < 1 THEN
		vr_lower_boundary := 1;
	END IF;
	
	vr_upper_boundary := vr_lower_boundary + vr_count - 1;
	
	DROP TABLE IF EXISTS instance_ids_34753;
	
	CREATE TEMP TABLE instance_ids_34753 (
		instance_id UUID primary key,
		owner_id 	UUID, 
		row_num 	BIGINT
	);
	
	vr_str_sbe_id := vr_sort_by_element_id::VARCHAR(100);
	vr_str_form_id := vr_form_id::VARCHAR(100);
	
	IF COALESCE(ARRAY_LENGTH(vr_instance_ids, 1), 0) > 0 THEN
		INSERT INTO instance_ids_34753 (instance_id, owner_id, row_num)
		SELECT	x, 
				fi.owner_id, 
				x.seq AS row_num
		FROM UNNEST(vr_instance_ids) WITH ORDINALITY AS x("value", seq)
			LEFT JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.instance_id = x
		ORDER BY x.seq ASC;
	
		vr_instances_count = (SELECT COUNT(*) FROM instance_ids_34753)::INTEGER;
	ELSE
		vr_proc := 'INSERT INTO instance_ids_34753 (instance_id, owner_id, row_num) ' || 
			'SELECT rf.instance_id, rf.owner_id, rf.row_num FROM ' || 
			'(SELECT ROW_NUMBER() OVER(ORDER BY r.row_num ASC) AS row_num, r.instance_id, r.owner_id ' ||
			'FROM (' ||
			'SELECT ROW_NUMBER() OVER(PARTITION BY fi.instance_id ORDER BY fi.instance_id) AS p, ' ||
			'ROW_NUMBER() OVER(ORDER BY ' ||
			(CASE WHEN vr_sort_by_element_id IS NULL THEN 'fi.instance_id ' ELSE 'ie.element_id ' END) ||
			(CASE WHEN vr_desc = TRUE THEN 'DESC ' ELSE '' END) ||
			') AS row_num, fi.instance_id, fi.owner_id FROM ' ||
			(CASE WHEN vr_has_owner = TRUE THEN 'owners_98239 AS ow INNER JOIN ' ELSE '' END) ||
			'fg_form_instances AS fi ' ||
			(CASE WHEN vr_has_owner = TRUE THEN 'ON fi.application_id = ''' ||
				vr_application_id::VARCHAR(50) || ''' AND fi.owner_id = ow.value ' ELSE '' END) ||
			(
				CASE 
					WHEN vr_sort_by_element_id IS NOT NULL
						THEN 'LEFT JOIN fg_instance_elements AS ie ' ||
							'ON ie.application_id = ''' || vr_application_id::VARCHAR(50) ||
								''' AND ie.instance_id = fi.instance_id AND ' ||
							'ie.ref_element_id = ''' || vr_str_sbe_id || ''' AND ie.deleted = FALSE '
					ELSE '' 
				END
			) ||
			'WHERE fi.form_id = ''' || vr_str_form_id || ''' AND fi.deleted = FALSE ' ||
			') AS r WHERE r.p = 1 ' ||
			') AS rf';
		
		EXECUTE vr_proc;
		
		GET DIAGNOSTICS vr_instances_count := ROW_COUNT;
	END IF;
	
	IF vr_instances_count > 0 AND COALESCE(ARRAY_LENGTH(vr_filters, 1), 0) > 0 THEN
		vr_cur_instance_ids := ARRAY(
			SELECT i.instance_id
			FROM instance_ids_34753 AS i
		);
		
		DELETE FROM instance_ids_34753 AS x
		USING (
				SELECT i.instance_id
				FROM instance_ids_34753 AS i
					LEFT JOIN fg_fn_filter_instances(
						vr_application_id, NULL, vr_cur_instance_ids, vr_filters, ',', TRUE
					) AS ret
					ON ret.instance_id = i.instance_id
				WHERE ret.instance_id IS NULL
			) AS y
		WHERE x.instance_id = y.instance_id;
	END IF;
	
	UPDATE instance_ids_34753
	SET row_num = CASE WHEN x.instance_id IS NULL THEN 0 ELSE x.row_num END
	FROM instance_ids_34753 AS i
		LEFT JOIN (
			SELECT	d.instance_id,
					d.owner_id,
					ROW_NUMBER() OVER (ORDER BY d.row_num ASC) AS row_num
			FROM (
					SELECT	i.instance_id,
							i.owner_id,
							ROW_NUMBER() OVER (ORDER BY i.row_num ASC) AS row_num
					FROM instance_ids_34753 AS i
				) AS d
			WHERE d.row_num BETWEEN vr_lower_boundary AND vr_upper_boundary
		) AS x
		ON x.instance_id = i.instance_id;
	
	DELETE FROM instance_ids_34753 AS x
	WHERE x.row_num = 0;
	
	vr_instances_count := (SELECT COUNT(*) FROM instance_ids_34753)::INTEGER;
	
	-- End of Preparing
	
	DROP TABLE IF EXISTS results_34523;
	
	CREATE TEMP TABLE results_34523
	(
		instance_id		UUID,
		owner_id		UUID,
		ref_element_id	UUID,
		creation_date 	TIMESTAMP,
		body_text	 	VARCHAR,
		row_num			BIGINT
	);

	INSERT INTO results_34523 (
		instance_id, 
		owner_id, 
		ref_element_id, 
		creation_date, 
		body_text, 
		row_num
	)
	SELECT	fi.instance_id, 
			instids.owner_id,
			elids, 
			fi.creation_date,
			fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value),
			instids.row_num
	FROM instance_ids_34753 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN UNNEST(vr_elem_ids) AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids
		ON ie.instance_id = fi.instance_id;

	vr_proc := 'SELECT * FROM (';
	
	WHILE vr_instances_count >= 0 LOOP
		IF vr_lower > 0 THEN 
			vr_proc = vr_proc || ' UNION ALL ';
		END IF;
		
		vr_proc := vr_proc || '(' ||
			'SELECT * ' ||
			'FROM crosstab(' ||
				'''' ||
				'SELECT r.instance_id, r.owner_id, r.creation_date, r.ref_element_id, r.body_text ' ||
				'FROM results_34523 AS r ' ||
				'WHERE r.row_num > ' || vr_lower::VARCHAR || ' AND ' || 
					'r.row_num <= ' || (vr_lower + vr_batch_size)::VARCHAR ||
				''', ' ||
				'''' ||
				ARRAY_TO_STRING(ARRAY(
					SELECT 'SELECT ''''' || REPLACE(REPLACE(x::VARCHAR, '(', ''), ')', '') || ''''''
					FROM UNNEST(vr_elem_ids) AS x
				), ' UNION ALL ', '') ||
				'''' ||
			') ' ||
			'AS (instance_id UUID, owner_id UUID, creation_date TIMESTAMP, ' || 
			ARRAY_TO_STRING(ARRAY(
				SELECT '"' || REPLACE(REPLACE(x::VARCHAR, '(', ''), ')', '') || '" VARCHAR'
				FROM UNNEST(vr_elem_ids) AS x
			), ', ', '') ||
			')' ||
			')';
		
		vr_instances_count := vr_instances_count - vr_batch_size;
		vr_lower := vr_lower + vr_batch_size;
	END LOOP;
	
	vr_proc := vr_proc || ') AS table_name';
	
	IF vr_sort_by_element_id IS NOT NULL AND vr_str_sbe_id IS NOT NULL THEN
		vr_proc = vr_proc || ' ORDER BY "' || vr_str_sbe_id || '"';
		
		IF vr_desc = TRUE THEN 
			vr_proc := vr_proc || ' DESC';
		END IF;
	END IF;
	
	OPEN vr_cursor FOR
	EXECUTE vr_proc;
	RETURN vr_cursor;
END;
$$ LANGUAGE plpgsql;

