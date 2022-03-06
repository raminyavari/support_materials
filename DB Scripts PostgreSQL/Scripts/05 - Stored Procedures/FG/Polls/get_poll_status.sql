DROP FUNCTION IF EXISTS fg_get_poll_status;

CREATE OR REPLACE FUNCTION fg_get_poll_status
(
	vr_application_id		UUID,
	vr_poll_id				UUID,
	vr_is_copy_of_poll_id	UUID,
	vr_current_user_id		UUID
)
RETURNS TABLE (
	description				VARCHAR,
	begin_date				TIMESTAMP,
	finish_date				TIMESTAMP,
	instance_id				UUID,
	elements_count			INTEGER, 
	filled_elements_count	INTEGER,
	all_filled_forms_count	INTEGER
)
AS
$$
DECLARE
	vr_description 				VARCHAR;
	vr_begin_date 				TIMESTAMP;
	vr_finish_date 				TIMESTAMP;
	vr_instance_id 				UUID;
	vr_elements_count 			INTEGER;
	vr_filled_elements_count 	INTEGER;
	vr_all_filled_forms_count	INTEGER;
	
	vr_limited_elements 		UUID[];
BEGIN
	IF vr_poll_id IS NULL THEN
		SELECT INTO vr_description 
					"p".description
		FROM fg_polls AS "p"
		WHERE "p".application_id = vr_application_id AND "p".poll_id = vr_is_copy_of_poll_id
		LIMIT 1;
	ELSE
		SELECT INTO vr_description, vr_begin_date, vr_finish_date, vr_instance_id
					COALESCE("p".description, rf.description), "p".begin_date, "p".finish_date, fi.instance_id
		FROM fg_polls AS "p"
			INNER JOIN fg_polls AS rf
			ON rf.application_id = vr_application_id AND rf.poll_id = "p".is_copy_of_poll_id
			INNER JOIN fg_form_owners AS fo
			ON fo.application_id = vr_application_id AND fo.owner_id = rf.poll_id AND fo.deleted = FALSE
			LEFT JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.form_id = fo.form_id AND 
				fi.owner_id = vr_poll_id AND fi.director_id = vr_current_user_id
		WHERE "p".application_id = vr_application_id AND "p".poll_id = vr_poll_id
		ORDER BY fi.creation_date DESC
		LIMIT 1;
	END IF;

	vr_limited_elements := ARRAY(
		SELECT rf.element_id
		FROM fg_fn_get_limited_elements(vr_application_id, vr_is_copy_of_poll_id) AS rf
	);
	
	SELECT INTO vr_elements_count, vr_filled_elements_count
				COUNT(DISTINCT l.value), COUNT(DISTINCT ie.element_id)
	FROM UNNEST(vr_limited_elements) AS l
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = l AND
			fg_fn_is_fillable(efe.type) = TRUE
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.instance_id = vr_instance_id AND 
			ie.ref_element_id = l AND ie.deleted = FALSE AND
			COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, 
				ie.type, ie.text_value, ie.float_value, ie.bit_value, ie.date_value), '') <> ''
	LIMIT 1;

	SELECT INTO vr_all_filled_forms_count
				COUNT(DISTINCT fi.director_id)
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND
			COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value), '') <> ''
		INNER JOIN UNNEST(vr_limited_elements) AS l
		ON l = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND fi.deleted = FALSE;
		
	RETURN QUERY
	SELECT	vr_description AS description,
			vr_beginDate AS begin_date,
			vr_finish_date AS finish_date,
			vr_instanceID AS instance_id,
			vr_elementsCount AS elements_count, 
			vr_filledElementsCount AS filled_elements_count,
			vr_allFilledFormsCount AS all_filled_forms_count;
END;
$$ LANGUAGE plpgsql;

