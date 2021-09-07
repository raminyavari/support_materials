DROP FUNCTION IF EXISTS fg_fn_to_string;

CREATE OR REPLACE FUNCTION fg_fn_to_string
(
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_type				VARCHAR(50),
	vr_text_value	 	VARCHAR,
	vr_float_value		FLOAT,
	vr_bit_value	 	BOOLEAN,
	vr_date_value		TIMESTAMP
)
RETURNS VARCHAR
AS
$$
BEGIN
	IF vr_type = 'File' THEN
		RETURN dct_fn_files_count(vr_application_id, vr_element_id)::VARCHAR;
	ELSEIF vr_type = 'Form' THEN
		RETURN COALESCE((
			SELECT COUNT(fi.instance_id)
			FROM fg_form_instances AS fi
			WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_element_id AND fi.deleted = FALSE
		), 0)::VARCHAR;
	ELSEIF vr_type = 'Node' OR vr_type = 'User' THEN
		RETURN vr_text_value;
	ELSEIF vr_text_value IS NOT NULL THEN 
		RETURN vr_text_value;
	ELSEIF vr_float_value IS NOT NULL THEN 
		RETURN vr_float_value::VARCHAR;
	ELSEIF vr_bit_value IS NOT NULL THEN 
		RETURN vr_bit_value::INTEGER::VARCHAR;
	ELSEIF vr_date_value IS NOT NULL THEN 
		RETURN vr_date_value::VARCHAR;
	ELSE
		RETURN N'';
	END IF;
END;
$$ LANGUAGE PLPGSQL;