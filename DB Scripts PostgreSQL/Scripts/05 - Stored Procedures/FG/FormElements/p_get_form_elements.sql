DROP FUNCTION IF EXISTS fg_p_get_form_elements;

CREATE OR REPLACE FUNCTION fg_p_get_form_elements
(
	vr_application_id	UUID,
	vr_element_ids		UUID[]
)
RETURNS SETOF fg_form_element_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT fe.element_id,
		   fe.form_id,
		   fe.title,
		   fe.name,
		   fe.help,
		   COALESCE(fe.necessary, FALSE)::BOOLEAN AS necessary,
		   COALESCE(fe.unique_value, FALSE)::BOOLEAN AS unique_value,
		   fe.sequence_number,
		   fe.type,
		   fe.info,
		   fe.weight,
		   0::INTEGER AS total_count
	FROM UNNEST(vr_element_ids) AS rf
		INNER JOIN fg_extended_form_elements AS fe
		ON fe.application_id = vr_application_id AND fe.element_id = rf
	ORDER BY fe.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;

