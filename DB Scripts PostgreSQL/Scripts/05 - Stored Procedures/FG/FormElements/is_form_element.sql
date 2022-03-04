DROP FUNCTION IF EXISTS fg_is_form_element;

CREATE OR REPLACE FUNCTION fg_is_form_element
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT rf.value AS "id"
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN fg_extended_form_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = rf.value
	UNION
	SELECT rf.value AS "id"
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN fg_instance_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = rf.value;
END;
$$ LANGUAGE plpgsql;

