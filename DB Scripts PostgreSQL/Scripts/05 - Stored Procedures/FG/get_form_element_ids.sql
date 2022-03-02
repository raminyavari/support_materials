DROP FUNCTION IF EXISTS fg_get_form_element_ids;

CREATE OR REPLACE FUNCTION fg_get_form_element_ids
(
	vr_application_id	UUID,
	vr_form_id			UUID,
	vr_element_names 	string_table_type[]
)
RETURNS TABLE (
	"name"		VARCHAR,
	element_id	UUID
)
AS
$$
BEGIN
	RETURN QUERY
	WITH "data" AS
	(
		SELECT DISTINCT LOWER(COALESCE(x.value, '')) AS "name"
		FROM UNNEST(vr_element_names) AS x
	)
	SELECT 	e.name, 
			e.element_id
	FROM "data" AS d
		INNER JOIN fg_extended_form_elements AS e
		ON e.application_id = vr_application_id AND e.form_id = vr_form_id AND 
			LOWER(COALESCE(e.name, '')) = d.name;
END;
$$ LANGUAGE plpgsql;

