DROP FUNCTION IF EXISTS fg_fn_check_element_value;

CREATE OR REPLACE FUNCTION fg_fn_check_element_value
(
	vr_type 		VARCHAR(20),
	vr_ref_text 	VARCHAR(2000), 
	vr_ref_float 	FLOAT, 
	vr_ref_bit 		BOOLEAN,
	vr_ref_date 	TIMESTAMP,
	vr_text 		VARCHAR,
	vr_text_items 	VARCHAR[],
	vr_or 			BOOLEAN,
	vr_exact 		BOOLEAN,
	vr_date_from 	TIMESTAMP,
	vr_date_to 		TIMESTAMP,
	vr_float_from 	FLOAT, 
	vr_float_to 	FLOAT, 
	vr_bit 			BOOLEAN,
	vr_no_text_item	BOOLEAN
)
RETURNS FLOAT
AS
$$
BEGIN
	IF vr_type = 'Text' OR vr_type = 'File' THEN 
		RETURN CASE 
			WHEN vr_no_text_item = TRUE THEN (CASE WHEN COALESCE(vr_ref_text, N'') = N'' THEN 1 ELSE 0 END)
			WHEN gfn_like_match(vr_ref_text, vr_text_items, vr_or, vr_exact) = TRUE THEN 1 
			ELSE 0 
		END;
	ELSEIF vr_type = 'MultiLevel' THEN
		RETURN CASE 
			WHEN COALESCE(vr_no_text_item, FALSE) = FALSE AND 
				EXISTS(SELECT * FROM UNNEST(vr_text_items) AS "t" WHERE "t" = vr_ref_text LIMIT 1) THEN 1 
			ELSE 0 
		END;
	ElSEIF vr_type = 'Checkbox' OR vr_type = 'Select' THEN
		IF vr_type = 'Select' THEN 
			vr_or := TRUE; 
		END IF;
	
		RETURN CASE
			WHEN vr_no_text_item = TRUE THEN (CASE WHEN COALESCE(vr_ref_text, N'') = N'' THEN 1 ELSE 0 END)
			WHEN COALESCE((
				SELECT SUM(CASE WHEN gfn_like_match(LTRIM(RTRIM(COALESCE("ref", N''))), vr_textItems, vr_or, vr_exact) = TRUE THEN 1 ELSE 0 END)
				FROM UNNEST(gfn_split_string(COALESCE(vr_ref_text, N''), N'~')) AS "ref"
			), 0) > 0 THEN 1
			ELSE 0
		END;
	ELSEIF vr_type = N'Date' THEN
		RETURN CASE 
			WHEN (vr_date_from IS NULL OR vr_ref_date >= vr_date_from) AND 
				(vr_date_to IS NULL OR vr_ref_date <= vr_date_to) THEN 1 
			ELSE 0 
		END;
	ELSEIF vr_type = N'Binary' THEN
		RETURN CASE 
			WHEN vr_bit IS NULL THEN (CASE WHEN vr_ref_bit IS NULL THEN 1 ELSE 0 END)
			WHEN vr_ref_bit = vr_bit THEN 1 
			ELSE 0 
		END;
	ELSEIF vr_type = N'Numeric' THEN
		RETURN CASE 
			WHEN (vr_float_from IS NULL OR vr_ref_float >= vr_float_from) AND 
				(vr_float_to IS NULL OR vr_ref_float <= vr_float_to) THEN 1 
			ELSE 0 
		END;
	ELSE 
		RETURN 0;
	END IF;
END;
$$ LANGUAGE PLPGSQL;