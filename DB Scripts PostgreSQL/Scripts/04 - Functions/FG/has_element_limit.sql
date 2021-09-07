DROP FUNCTION IF EXISTS fg_fn_has_element_limit;

CREATE OR REPLACE FUNCTION fg_fn_has_element_limit
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
		FROM fg_element_limits AS l
			INNER JOIN fg_form_owners AS fo
			ON fo.application_id = vr_application_id AND fo.owner_id = vr_owner_id
			INNER JOIN fg_extended_form_elements AS e
			ON e.application_id = vr_application_id AND 
				e.element_id = l.element_id AND e.deleted = FALSE
		WHERE l.application_id = vr_application_id AND l.owner_id = vr_owner_id AND l.deleted = FALSE
		LIMIT 1
	), FALSE);
END;
$$ LANGUAGE PLPGSQL;