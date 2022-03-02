DROP FUNCTION IF EXISTS fg_set_elements_order;

CREATE OR REPLACE FUNCTION fg_set_elements_order
(
	vr_application_id	UUID,
	vr_element_ids	 	guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_form_id	UUID;
	vr_result	INTEGER;
BEGIN
	SELECT vr_form_id = e.form_id
	FROM fg_extended_form_elements AS e
	WHERE e.application_id = vr_application_id AND 
		e.element_id = (SELECT rf.value FROM UNNEST(vr_element_ids) AS rf LIMIT 1);
	
	IF vr_form_id IS NULL THEN
		RETURN -1::INTEGER;
	END IF;
	
	vr_element_ids := ARRAY(
		(SELECT ROW(x.value)
		FROM UNNEST(vr_element_ids) WITH ORDINALITY AS x("value", seq)
		ORDER BY x.seq ASC)
		
		UNION ALL
		
		SELECT ROW(e.element_id)
		FROM UNNEST(vr_element_ids) AS rf
			RIGHT JOIN fg_extended_form_elements AS e
			ON e.element_id = rf.value
		WHERE e.application_id = vr_application_id AND 
			e.form_id = vr_form_id AND rf.element_id IS NULL
		ORDER BY e.sequence_number ASC
	);
	
	UPDATE fg_extended_form_elements
	SET sequence_number = x.seq
	FROM UNNEST(vr_element_ids) WITH ORDINALITY AS x("value", seq)
		INNER JOIN fg_extended_form_elements AS e
		ON e.element_id = x.value
	WHERE e.application_id = vr_application_id AND e.form_id = vr_form_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

