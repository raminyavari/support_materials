DROP FUNCTION IF EXISTS fg_fn_filter_instances;

CREATE OR REPLACE FUNCTION fg_fn_filter_instances
(
	vr_application_id	UUID,
	vr_owner_element_id	UUID,
	vr_instance_ids		UUID[],
	vr_form_filters		form_filter_table_type[],
	vr_delimiter		CHAR,
	vr_match_all	 	BOOLEAN
)
RETURNS TABLE (
	instance_id	UUID, 
	"rank" 		FLOAT
)
AS
$$
DECLARE
	vr_element_id 		UUID;
	vr_type 			VARCHAR(20);
	vr_text 			VARCHAR;
	vr_str_text_items 	VARCHAR;
	vr_or 				BOOLEAN;
	vr_exact 			BOOLEAN;
	vr_date_from 		TIMESTAMP;
	vr_date_to 			TIMESTAMP;
	vr_float_from 		FLOAT;
	vr_float_to 		FLOAT;
	vr_bit 				BOOLEAN;
	vr_str_guid_items	VARCHAR;
	vr_compulsory 		BOOLEAN;
	
	vr_iter 			INTEGER;
	vr_count 			INTEGER;
	vr_compulsory_count	INTEGER;
	
	vr_text_items 		VARCHAR[];
	vr_guid_items 		UUID;
	vr_no_text_item 	BOOLEAN;
	vr_no_guid_item 	BOOLEAN;
	
	vr_owner_ids 		UUID[];
	vr_max_score 		FLOAT;
BEGIN
	DROP TABLE IF EXISTS vr_fltrs_52623;
	DROP TABLE IF EXISTS vr_ret_inst_ids_62084;
	DROP TABLE IF EXISTS vr_inst_elems_72038;

	CREATE TEMP TABLE vr_fltrs_52623 (
		"id" 		SERIAL, 
		element_id 	UUID, 
		"type" 		VARCHAR(20), 
		Compulsory	BOOLEAN
	);
	
	CREATE TEMP TABLE vr_ret_inst_ids_62084 (
		instance_id 		UUID primary key,
		"rank" 				FLOAT,
		match_count 		INTEGER,
		compulsory_count	INTEGER
	);
			
	CREATE TEMP TABLE vr_inst_elems_72038 (
		element_id 	UUID, 
		instance_id	UUID, 
		score 		FLOAT
	);
	
	INSERT INTO vr_fltrs_52623 (element_id, "type", compulsory)
	SELECT "ref".element_id, e.type, "ref".compulsory
	FROM UNNEST(vr_form_filters) AS "ref"
		INNER JOIN fg_extended_form_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = "ref".element_id
	WHERE ("ref".owner_id IS NULL AND vr_owner_element_id IS NULL) OR "ref".owner_id = vr_owner_element_id;
	
	vr_iter := (SELECT COUNT(*) FROM vr_fltrs_52623);
	vr_count := vr_iter;
	vr_compulsory_count := (SELECT COUNT(f.id) FROM vr_fltrs_52623 AS f WHERE COALESCE(f.compulsory, FALSE) = TRUE);
	
	INSERT INTO vr_ret_inst_ids_62084 (instance_id, "rank", match_count, compulsory_count)
	SELECT "ref", 0, 0, 0
	FROM UNNEST(vr_instance_ids) AS "ref";
	
	WHILE vr_iter > 0 LOOP
		SELECT	vr_element_id = ff.element_id,
				vr_type = f.type,
				vr_text = ff.text,
				vr_str_text_items = ff.text_items,
				vr_or = ff.or,
				vr_exact = ff.exact,
				vr_date_from = ff.date_from,
				vr_date_to = ff.date_to,
				vr_float_from = ff.float_from,
				vr_float_to = ff.float_to,
				vr_bit = ff.bit,
				vr_str_guid_items = ff.guid_items,
				vr_compulsory = f.compulsory
		FROM vr_fltrs_52623 AS f
			INNER JOIN UNNEST(vr_form_filters) AS ff
			ON f.element_id = ff.element_id
		WHERE f.id = vr_iter;
		
		IF vr_text = N'' THEN 
			vr_text := NULL;
		END IF;
		
		vr_text_items := gfn_split_string(vr_str_text_items, vr_delimiter);
		vr_guid_items := ARRAY(
			SELECT x::UUID
			FROM UNNEST(gfn_split_string(vr_str_guid_items, vr_delimiter)) AS x
		);
		vr_no_text_item := CASE WHEN COALESCE(ARRAY_LENGTH(vr_text_items, 1), 0) = 0 THEN TRUE ELSE FALSE END;
		vr_no_guid_item := CASE WHEN COALESCE(ARRAY_LENGTH(vr_guid_items, 1), 0) = 0 THEN TRUE ELSE FALSE END;
		
		
		IF vr_type = 'Form' THEN
			DELETE FROM vr_inst_elems_72038;
			
			INSERT INTO vr_inst_elems_72038 (element_id, instance_id)
			SELECT ie.element_id, "ref".instance_id
			FROM vr_ret_inst_ids_62084 AS "ref"
				INNER JOIN fg_instance_elements AS ie
				ON ie.application_id = vr_application_id AND ie.instance_id = "ref".instance_id
			WHERE ie.ref_element_id = vr_element_id AND ie.deleted = FALSE;
			
			vr_owner_ids := ARRAY(
				SELECT DISTINCT i.element_id
				FROM vr_inst_elems_72038 AS i
			);
			
			UPDATE vr_inst_elems_72038
			SET score = "ref".rank
			FROM vr_inst_elems_72038 AS i
				INNER JOIN fg_fn_filter_instance_owners(vr_application_id, 
					vr_element_id, vr_owner_ids, vr_form_filters, vr_match_all) AS "ref"
				ON "ref".owner_id = i.element_id;
				
			vr_max_score := (SELECT MAX(score) FROM vr_inst_elems_72038);
			
			IF vr_max_score IS NULL OR vr_max_score <= 0 THEN
				vr_max_score := 1;
			END IF;
			
			UPDATE vr_ret_inst_ids_62084
			SET "rank" = "rank" + (i.score / vr_max_score),
				match_count = match_count + 1,
				compulsory_count = compulsory_count + COALESCE(vr_compulsory, FALSE)::INTEGER
			FROM vr_ret_inst_ids_62084 AS r
				INNER JOIN vr_inst_elems_72038 AS i
				ON i.instance_id = r.instance_id
			WHERE COALESCE(i.score, 0) > 0;
		ELSEIF vr_type = 'File' THEN
			UPDATE vr_ret_inst_ids_62084
			SET "rank" = "rank" + x.score,
				match_count = match_count + 1,
				compulsory_count = compulsory_count + COALESCE(vr_compulsory, FALSE)::INTEGER
			FROM vr_ret_inst_ids_62084 AS "ref"
				INNER JOIN (
					SELECT	"ref".instance_id,
							fg_fn_check_element_value(
								ie.type, f.file_name, NULL, NULL, NULL, 
								vr_text, vr_text_items, vr_or, vr_exact, vr_date_from, vr_date_to, 
								vr_float_from, vr_float_to, vr_bit, vr_no_text_item
							) AS score
					FROM vr_ret_inst_ids_62084 AS "ref"
						INNER JOIN fg_instance_elements AS ie
						ON ie.application_id = vr_application_id AND ie.instance_id = "ref".instance_id
						INNER JOIN dct_files AS f
						ON f.application_id = vr_application_id AND f.owner_id = ie.element_id
					WHERE ie.ref_element_id = vr_element_id AND ie.deleted = FALSE
				) AS x
				ON x.instance_id = "ref".instance_id
			WHERE x.score > 0;
		ELSEIF vr_type = 'Node' OR vr_type = 'User' THEN
			UPDATE vr_ret_inst_ids_62084
			SET "rank" = "rank" + x.score,
				match_count = match_count + 1,
				compulsory_count = compulsory_count + COALESCE(vr_compulsory, FALSE)::INTEGER
			FROM vr_ret_inst_ids_62084 AS "ref"
				INNER JOIN (
					SELECT	"ref".instance_id,
							COUNT("g")::FLOAT AS score
					FROM vr_ret_inst_ids_62084 AS "ref"
						INNER JOIN fg_instance_elements AS ie
						ON ie.application_id = vr_application_id AND ie.instance_id = "ref".instance_id
						INNER JOIN fg_selected_items AS s
						ON s.application_id = vr_application_id AND 
							s.element_id = ie.element_id AND s.deleted = FALSE
						INNER JOIN UNNEST(vr_guid_items) AS "g"
						ON "g" = s.selected_id
					WHERE ie.ref_element_id = vr_element_id AND ie.deleted = FALSE
					GROUP BY "ref".instance_id
				) AS x
				ON x.instance_id = "ref".instance_id
			WHERE vr_no_guid_item = FALSE AND x.score > 0;
		ELSE
			UPDATE vr_ret_inst_ids_62084
			SET "rank" = "rank" + x.score,
				match_count = match_count + 1,
				compulsory_count = compulsory_count + COALESCE(vr_compulsory, FLASE)::INTEGER
			FROM vr_ret_inst_ids_62084 AS "ref"
				INNER JOIN (
					SELECT	"ref".instance_id,
							fg_fn_check_element_value(
								COALESCE(ie.type, vr_type), ie.text_value, ie.float_value, ie.bit_value, ie.date_value, 
								vr_text, vr_text_items, vr_or, vr_exact, vr_date_from, vr_date_to, 
								vr_float_from, vr_float_to, vr_bit, vr_no_text_item
							) AS score
					FROM vr_ret_inst_ids_62084 AS "ref"
						LEFT JOIN fg_instance_elements AS ie
						ON ie.application_id = vr_application_id AND ie.instance_id = "ref".instance_id AND
							ie.ref_element_id = vr_element_id AND ie.deleted = FALSE
				) AS x
				ON x.instance_id = ref.instance_id
			WHERE x.score > 0;
		END IF;
		
		vr_iter := vr_iter - 1;
	END LOOP;
	
	RETURN QUERY
	SELECT "ref".instance_id, "ref".rank
	FROM vr_ret_inst_ids_62084 AS "ref"
	WHERE "ref".rank > 0 AND (COALESCE(vr_match_all, FALSE) = FALSE OR "ref".match_count = vr_count) AND 
		"ref".compulsory_count = vr_compulsory_count AND (
			CASE
				WHEN vr_count > vr_compulsory_count THEN 
					(CASE WHEN "ref".match_count > "ref".compulsory_count THEN TRUE ELSE FALSE END)
				ELSE TRUE
			END
		) = TRUE;
END;
$$ LANGUAGE PLPGSQL;