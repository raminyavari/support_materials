DROP FUNCTION IF EXISTS fg_fn_has_form_content;

CREATE OR REPLACE FUNCTION fg_fn_has_form_content
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM fg_form_instances AS i
			INNER JOIN fg_instance_elements AS e
			ON e.application_id = vr_application_id AND e.instance_id = i.instance_id
		WHERE i.application_id = vr_application_id AND i.owner_id = vr_owner_id AND 
			i.deleted = FALSE AND e.deleted = FALSE AND (
				COALESCE(fg_fn_to_string(vr_application_id, e.element_id, e.type, 
					e.text_value, e.float_value, e.bit_value, e.date_value), N'') <> N''
			)
		LIMIT 1
	), FALSE);
END;
$$ LANGUAGE PLPGSQL;