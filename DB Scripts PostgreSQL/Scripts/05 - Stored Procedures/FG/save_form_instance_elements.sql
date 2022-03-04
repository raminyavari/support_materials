DROP FUNCTION IF EXISTS fg_save_form_instance_elements;

CREATE OR REPLACE FUNCTION fg_save_form_instance_elements
(
	vr_application_id		UUID,
	vr_elements				form_element_table_type[],
	vr_guid_items			guid_pair_table_type[],
	vr_elements_to_clear	guid_table_type[],
	vr_files				doc_file_info_table_type[],
	vr_current_user_id		UUID,
	vr_now					TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result_1			INTEGER;
	vr_result_2			INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM fg_fn_check_unique_constraint(vr_application_id, vr_elements)
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'UniqueConstriantHasNotBeenMet');
		RETURN -1::INTEGER;
	END IF;
	
	-- Find Main ElementIDs
	WITH main_ids AS 
	(
		SELECT DISTINCT 
			rf.element_id, 
			ie1.element_id AS main_element_id
		FROM UNNEST(vr_elements) AS rf
			LEFT JOIN fg_instance_elements AS ie
			ON ie.application_id = vr_application_id AND ie.element_id = rf.element_id
			INNER JOIN fg_instance_elements AS ie1
			ON ie1.application_id = vr_application_id AND
				rf.ref_element_id IS NOT NULL AND rf.instance_id IS NOT NULL AND
				ie1.ref_element_id = rf.ref_element_id AND ie1.instance_id = rf.instance_id
		WHERE ie.element_id IS NULL	
	)
	SELECT INTO vr_guid_items 
				ARRAY(
					SELECT ROW(COALESCE("m".main_element_id, e.first_value), e.second_value)
					FROM UNNEST(vr_guid_items) AS e
						LEFT JOIN main_ids AS "m"
						ON "m".element_id = e.first_value
				);
	-- end of Find Main ElementIDs
	
	
	-- Save Changes
	INSERT INTO fg_changes (
		application_id, 
		element_id, 
		text_value, 
		float_value, 
		bit_value, 
		date_value, 
		creator_user_id, 
		creation_date, 
		deleted)
	SELECT 	vr_application_id, 
			COALESCE(e.element_id, x.element_id), 
			gfn_verify_string(x.text_value), 
			x.float_value, 
			x.bit_value, 
			x.date_value, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM (
			SELECT	"c".value AS element_id, 
					i.ref_element_id AS ref_element_id,
					i.instance_id,
					NULL::VARCHAR AS text_value,
					NULL::FLOAT AS float_value,
					NULL::BOOLEAN AS bit_value,
					NULL::TIMESTAMP AS date_value
			FROM UNNEST(vr_elements_to_clear) AS "c"
				LEFT JOIN UNNEST(vr_elements) AS e
				ON e.element_id = "c".value
				INNER JOIN fg_instance_elements AS i
				ON i.application_id = vr_application_id AND i.element_id = "c".value
			WHERE e.element_id IS NULL
			
			UNION ALL
			
			SELECT 	e.element_id, 
					e.ref_element_id, 
					e.instance_id,
					e.text_value, 
					e.float_value, 
					e.bit_value, 
					e.date_value
			FROM UNNEST(vr_elements) AS e
		) AS x
		LEFT JOIN fg_instance_elements AS e -- First part checks element_id. We split them for performance reasons
		ON e.application_id = vr_application_id AND e.element_id = x.element_id
		LEFT JOIN fg_instance_elements AS e1 -- Second part checks InstanceID and RefElementID
		ON e1.application_id = vr_application_id AND
			x.ref_element_id IS NOT NULL AND x.instance_id IS NOT NULL AND 
			e1.ref_element_id = x.ref_element_id AND e1.instance_id = x.instance_id
	WHERE (COALESCE(e.element_id, e1.element_id) IS NULL AND 
			NOT (x.text_value IS NULL AND x.float_value IS NULL AND
				x.bit_value IS NULL AND x.date_value IS NULL
			)
		) OR 
		(x.text_value IS NULL AND COALESCE(e.text_value, e1.text_value) IS NOT NULL) OR
		(x.text_value IS NOT NULL AND COALESCE(e.text_value, e1.text_value) IS NULL) OR
		(x.text_value IS NOT NULL AND COALESCE(e.text_value, e1.text_value) IS NOT NULL AND 
			x.text_value <> COALESCE(e.text_value, e1.text_value)) OR
		(x.float_value IS NULL AND COALESCE(e.float_value, e1.float_value) IS NOT NULL) OR
		(x.float_value IS NOT NULL AND COALESCE(e.float_value, e1.float_value) IS NULL) OR
		(x.float_value IS NOT NULL AND COALESCE(e.float_value, e1.float_value) IS NOT NULL AND 
			x.float_value <> COALESCE(e.float_value, e1.float_value)) OR
		(x.bit_value IS NULL AND COALESCE(e.bit_value, e1.bit_value) IS NOT NULL) OR
		(x.bit_value IS NOT NULL AND COALESCE(e.bit_value, e1.bit_value) IS NULL) OR
		(x.bit_value IS NOT NULL AND COALESCE(e.bit_value, e1.bit_value) IS NOT NULL AND 
			x.bit_value <> COALESCE(e.bit_value, e1.bit_value)) OR
		(x.date_value IS NULL AND COALESCE(e.date_value, e1.date_value) IS NOT NULL) OR
		(x.date_value IS NOT NULL AND COALESCE(e.date_value, e1.date_value) IS NULL) OR
		(x.date_value IS NOT NULL AND COALESCE(e.date_value, e1.date_value) IS NOT NULL AND 
			x.date_value <> COALESCE(e.date_value, e1.date_value));
	-- end of Save Changes
	
	-- Update Existing Data
	-- A: Update based on element_id. We split them for performance reasons
	UPDATE fg_instance_elements
	SET text_value = gfn_verify_string(rf.text_value),
		float_value = rf.float_value,
		bit_value = rf.bit_value,
		date_value = rf.date_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
	 	deleted = FALSE
	FROM UNNEST(vr_elements) AS rf
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = rf.element_id;
	
	-- B: Update based on RefElementID and InstanceID
	UPDATE fg_instance_elements
	SET text_value = gfn_verify_string(rf.text_value),
		float_value = rf.float_value,
		bit_value = rf.bit_value,
		date_value = rf.date_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		deleted = FALSE
	FROM UNNEST(vr_elements) AS rf
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND
			ie.ref_element_id = rf.ref_element_id AND ie.instance_id = rf.instance_id;
	-- end of Update Existing Data
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	-- Clear Empty Elements
	UPDATE fg_instance_elements
	SET text_value = NULL,
		float_value = NULL,
		bit_value = NULL,
		date_value = NULL,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		deleted = FALSE
	FROM UNNEST(vr_elements_to_clear) AS rf
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = rf.value;
		
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;
		
	vr_result_2 := vr_result_1 + vr_result_2;
		
	vr_result_1 := dct_p_remove_owners_files(
		vr_application_id, 
		ARRAY(
			SELECT DISTINCT owner_ids.value
			FROM (
					SELECT "c".value
					FROM UNNEST(vr_elements_to_clear) AS "c"

					UNION ALL 

					SELECT f.owner_id AS "value"
					FROM UNNEST(vr_files) AS f
				) AS owner_ids
		)
	);
	-- end of Clear Empty Elements
	
	INSERT INTO fg_instance_elements (
		application_id,
		element_id,
		instance_id,
		ref_element_id,
		title,
		sequence_number,
		"type",
		"info",
		text_value,
		float_value,
		bit_value,
		date_value,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT 	vr_application_id,
		   	rf.element_id,
		   	rf.instance_id,
		   	rf.ref_element_id,
		   	efe.title,
		   	COALESCE(efe.sequence_number, rf.sequence_nubmer),
		   	efe.type,
		   	efe.info,
		   	gfn_verify_string(rf.text_value),
		   	rf.float_value,
		   	rf.bit_value,
		   	rf.date_value,
		   	vr_current_user_id,
		   	vr_now,
		   	FALSE
	FROM UNNEST(vr_elements) AS rf
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = rf.ref_element_id
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.element_id = rf.element_id
		LEFT JOIN fg_instance_elements AS ie1
		ON ie1.application_id = vr_application_id AND
			ie1.ref_element_id = rf.ref_element_id AND ie1.instance_id = rf.instance_id
	WHERE COALESCE(ie.element_id, ie1.element_id) IS NULL;
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	vr_result_2 := vr_result_1 + vr_result_2 + 1;
	
	vr_result_1 := dct_p_add_files(vr_application_id, NULL, NULL, vr_files, vr_current_user_id, vr_now);
	
	-- Set Selected Guids
	UPDATE fg_selected_items
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM (
			SELECT DISTINCT "a".element_id
			FROM UNNEST(vr_elements) AS "a"
			
			UNION
			
			SELECT DISTINCT "c".value
			FROM UNNEST(vr_elements_to_clear) AS "c"
		) AS e
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND s.element_id = e.element_id;
	
	UPDATE fg_selected_items
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_guid_items) AS "g"
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND 
			s.element_id = "g".first_value AND s.selected_id = "g".second_value;
	
	INSERT INTO fg_selected_items (
		application_id, 
		element_id, 
		selected_id, 
		last_modifier_user_id, 
		last_modification_date, 
		deleted
	)
	SELECT 	vr_application_id, 
			"g".first_value, 
			"g".second_value, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_guid_items) AS "g"
		INNER JOIN fg_instance_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = "g".first_value
		LEFT JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND 
			s.element_id = "g".first_value AND s.selected_id = "g".second_value
	WHERE s.element_id IS NULL;
	-- end of Set Selected Guids
	
	RETURN vr_result_2;
END;
$$ LANGUAGE plpgsql;

