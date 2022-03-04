DROP FUNCTION IF EXISTS fg_meets_unique_constraint;

CREATE OR REPLACE FUNCTION fg_meets_unique_constraint
(
	vr_application_id	UUID,
	vr_instance_id		UUID,
	vr_element_id		UUID,
	vr_text_value	 	VARCHAR,
	vr_float_value		FLOAT
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_ref_element_id	UUID;
BEGIN
	SELECT vr_ref_element_id = e.ref_element_id
	FROM fg_instance_elements AS e
	WHERE e.application_id = vr_application_id AND e.element_id = vr_element_id
	LIMIT 1;
	
	DROP TABLE IF EXISTS elements_23532;
	
	CREATE TEMP TABLE elements_23532 OF form_element_table_type;
	
	INSERT INTO elements_23532 (
		element_id,
		instance_id, 
		ref_element_id, 
		text_value, 
		float_value, 
		sequence_number, 
		"type"
	)
	SELECT 	vr_element_id, 
			vr_instance_id, 
			vr_ref_element_id, 
			vr_text_value, 
			vr_float_value, 
			0::INTEGER AS seq, 
			'' AS "type";
	
	RETURN COALESCE((
		SELECT TRUE
		WHERE vr_instance_id IS NOT NULL AND (
			(COALESCE(vr_text_value, '') = '' AND vr_float_value IS NULL) OR 
			NOT EXISTS (
				SELECT 1
				FROM fg_fn_check_unique_constraint(vr_application_id, ARRAY(SELECT y FROM elements_23532 AS y)) AS x
				LIMIT 1
			))
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

