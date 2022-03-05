DROP FUNCTION IF EXISTS fg_convert_form_to_table;

CREATE OR REPLACE FUNCTION fg_convert_form_to_table
(
	vr_application_id	UUID,
	vr_form_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_table_name		VARCHAR(200);
	vr_instances_count 	INTEGER DEFAULT 0;
	vr_batch_size 		INTEGER DEFAULT 1000;
	vr_lower 			INTEGER DEFAULT 0;
	vr_columns 			VARCHAR;
	vr_columns2 		VARCHAR;
	vr_select_lst 		VARCHAR;
	vr_proc 			VARCHAR;
BEGIN
	-- Preparing

	DROP TABLE IF EXISTS element_ids_34543;
	
	CREATE TEMP TABLE element_ids_34543 (
		seq 	SERIAL primary key, 
		"value" UUID, 
		"name" 	VARCHAR(200)
	);

	SELECT INTO vr_table_name 
				'fg_frm_' || f.name
	FROM fg_extended_forms AS f
	WHERE f.application_id = vr_application_id AND f.form_id = vr_form_id AND 
		COALESCE(f.name, '') <> '' AND f.deleted = FALSE
	LIMIT 1;
	
	IF COALESCE(vr_table_name, '') = '' THEN
		RETURN -1::INTEGER;
	END IF;

	INSERT INTO element_ids_34543 ("value", "name")
	SELECT efe.element_id, 'col_' || efe.name
	FROM fg_extended_form_elements AS efe
	WHERE efe.application_id = vr_application_id AND efe.form_id = vr_form_id AND 
		COALESCE(efe.name, '') <> '' AND efe.deleted = FALSE
	ORDER BY efe.sequence_number ASC;
	
	IF (SELECT COUNT(*) FROM element_ids_34543) = 0 THEN
		RETURN -1::INTEGER;
	END IF;
	
	DROP TABLE IF EXISTS instance_ids_93274;
	
	CREATE TEMP TABLE instance_ids_93274 (
		instance_id 	UUID primary key, 
		owner_id 		UUID,
		creator_id 		UUID,
		creation_date 	TIMESTAMP,
		row_num 		BIGINT
	);

	INSERT INTO instance_ids_93274 (row_num, instance_id, owner_id, creator_id, creation_date)
	SELECT	ROW_NUMBER() OVER(ORDER BY fi.creation_date ASC, fi.instance_id ASC) AS row_num, 
			fi.instance_id,
			fi.owner_id,
			fi.creator_user_id,
			fi.creation_date
	FROM fg_form_instances AS fi 
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = fi.owner_id
	WHERE fi.application_id = vr_application_id AND fi.form_id = vr_form_id AND fi.deleted = FALSE AND 
		(nd.node_id IS NULL OR COALESCE(nd.deleted, FALSE) = FALSE);

	UPDATE instance_ids_93274
	SET row_num = CASE WHEN x.instance_id IS NULL THEN 0 ELSE x.row_num END
	FROM instance_ids_93274 AS i
		LEFT JOIN (
			SELECT	i.instance_id,
					ROW_NUMBER() OVER (ORDER BY i.row_num ASC) AS row_num
			FROM instance_ids_93274 AS i
		) AS x
		ON x.instance_id = i.instance_id;

	DELETE FROM instance_ids_93274 AS i
	WHERE i.row_num = 0;

	vr_instances_count := (SELECT COUNT(*) FROM instance_ids_93274);

	-- End of Preparing


	DROP TABLE IF EXISTS result_34723;

	CREATE TEMP TABLE result_34723 (
		instance_id UUID, 
		"name" 		VARCHAR(200), 
		"value"		VARCHAR, 
		row_num 	BIGINT
	);

	INSERT INTO result_34723 (instance_id, "name", "value", row_num)
	SELECT	fi.instance_id, 
			elids.name, 
			fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value),
			instids.row_num
	FROM instance_ids_93274 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN element_ids_34543 AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id;

	INSERT INTO result_34723 (instance_id, "name", "value", row_num)
	SELECT	fi.instance_id, 
			elids.name || '_id', 
			ie.element_id::VARCHAR,
			instids.row_num
	FROM instance_ids_93274 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN element_ids_34543 AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id;

	INSERT INTO result_34723 (instance_id, "name", "value", row_num)
	SELECT	fi.instance_id, 
			elids.name || '_text', 
			ie.text_value::VARCHAR,
			instids.row_num
	FROM instance_ids_93274 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN element_ids_34543 AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id;

	INSERT INTO result_34723 (instance_id, "name", "value", row_num)
	SELECT	fi.instance_id, 
			elids.name || '_float', 
			ie.float_value::VARCHAR,
			instids.row_num
	FROM instance_ids_93274 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN element_ids_34543 AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id;
			
	INSERT INTO result_34723 (instance_id, "name", "value", row_num)
	SELECT	fi.instance_id, 
			elids.name || '_bit', 
			ie.bit_value::VARCHAR,
			instids.row_num
	FROM instance_ids_93274 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN element_ids_34543 AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id;
		
	INSERT INTO result_34723 (instance_id, "name", "value", row_num)
	SELECT	fi.instance_id, 
			elids.name || '_date', 
			ie.date_value::VARCHAR,
			instids.row_num
	FROM instance_ids_93274 AS instids
		LEFT JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = instids.instance_id
		LEFT JOIN element_ids_34543 AS elids
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = elids.value
		ON ie.instance_id = fi.instance_id;

	vr_columns := ARRAY_TO_STRING(ARRAY(
		SELECT 	'SELECT ''''' || rf.name || '''''' || 
				' UNION ALL ' ||
				'SELECT ''''' || rf.name || '_id''''' || 
				' UNION ALL ' ||
				'SELECT ''''' || rf.name || '_text''''' || 
				' UNION ALL ' ||
				'SELECT ''''' || rf.name || '_float''''' || 
				' UNION ALL ' ||
				'SELECT ''''' || rf.name || '_bit''''' || 
				' UNION ALL ' ||
				'SELECT ''''' || rf.name || '_date'''''
		FROM element_ids_34543 AS rf
	), ' UNION ALL ', '');
	
	vr_columns2 := ARRAY_TO_STRING(ARRAY(
		SELECT 	'"' || rf.name || '" VARCHAR' || 
				', ' ||
				'"' || rf.name || '_id" UUID' || 
				', ' ||
				'"' || rf.name || '_text" VARCHAR' || 
				', ' ||
				'"' || rf.name || '_float" FLOAT' || 
				', ' ||
				'"' || rf.name || '_bit" BOOLEAN' || 
				', ' ||
				'"' || rf.name || '_date" TIMESTAMP'
		FROM element_ids_34543 AS rf
	), ', ', '');
	
	vr_select_lst := ARRAY_TO_STRING(ARRAY(
		SELECT 	'pvt.' || rf.name ||
				', ' ||
				'pvt.' || rf.name || '_id::UUID AS "' || rf.name || '_id"' ||
				', ' ||
				'pvt.' || rf.name || '_text' ||
				', ' ||
				'pvt.' || rf.name || '_float::FLOAT AS "' || rf.name || '_float"' || 
				', ' ||
				'pvt.' || rf.name || '_bit::BOOLEAN AS "' || rf.name || '_bit"' ||
				', ' ||
				'pvt.' || rf.name || '_date::TIMESTAMP AS "' || rf.name || '_date"'
		FROM element_ids_34543 AS rf
	), ', ', '');
	
	
	-- drop old table
	
	vr_proc := 'DROP TABLE IF EXISTS ' || vr_table_name;

	EXECUTE vr_proc;
	
	-- end of drop old table
	
	
	-- create new table
	
	vr_proc := 'CREATE TABLE IF NOT EXISTS ' || vr_table_name || ' (' ||
		'"instance_id" UUID NOT NULL PRIMARY KEY, ' ||
		'"owner_id" UUID, ' ||
		'"creation_date" TIMESTAMP, ' ||
		'"user_id" UUID, ' ||
		'"username" VARCHAR(200), ' ||
		'"first_name" VARCHAR(200), ' ||
		'"last_name" VARCHAR(200), ' ||
		vr_columns2 || ')';
		
	EXECUTE vr_proc;
	
	-- end of create new table
	

	vr_proc = 'INSERT INTO ' || vr_table_name || ' SELECT "all_data".* FROM (';

	WHILE vr_instances_count >= 0 LOOP
		IF vr_lower > 0 THEN 
			vr_proc := vr_proc || ' UNION ALL ';
		END IF;
		
		vr_proc := vr_proc || 
			'(SELECT pvt.instance_id, i.owner_id, i.creation_date, ' || 
				'un.user_id, un.username, un.first_name, un.last_name, ' || vr_select_lst || ' ' ||
			'FROM crosstab( ' ||
					'''' ||
					'SELECT r.instance_id, r.name, MAX(r.value) AS "value" ' ||
					'FROM result_34723 AS r ' ||
					'WHERE r.row_num > ' || vr_lower::VARCHAR || ' AND ' ||
						'r.row_num <= ' || (vr_lower + vr_batch_size)::VARCHAR || ' ' ||
					'GROUP BY r.instance_id, r.name ' ||
					'ORDER BY r.instance_id, r.name''' ||
					', ' ||
					'''' ||
					vr_columns ||
					'''' ||
				') AS pvt("instance_id" UUID, ' || vr_columns2 || ') ' ||
				'INNER JOIN instance_ids_93274 AS i ' ||
				'ON i.instance_id = pvt.instance_id ' ||
				'LEFT JOIN usr_view_users AS un ' ||
				'ON un.user_id = i.creator_id)';
		
		vr_instances_count := vr_instances_count - vr_batch_size;
		vr_lower = vr_lower + vr_batch_size;
	END LOOP;

	vr_proc := vr_proc || ') AS "all_data"';

	EXECUTE vr_proc;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

