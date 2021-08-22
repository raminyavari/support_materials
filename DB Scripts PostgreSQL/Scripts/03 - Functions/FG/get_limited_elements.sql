DROP FUNCTION IF EXISTS fg_fn_get_limited_elements;

CREATE OR REPLACE FUNCTION fg_fn_get_limited_elements
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS TABLE (
	element_id	UUID
)
AS
$$
BEGIN
	IF fg_fn_has_element_limit(vr_application_id, vr_owner_id) = TRUE THEN
		RETURN QUERY
		SELECT l.element_id
		FROM fg_element_limits AS l
			INNER JOIN fg_form_owners AS fo
			ON fo.application_id = vr_application_id AND fo.owner_id = vr_owner_id AND fo.deleted = FALSE
			INNER JOIN fg_extended_form_elements AS e
			ON e.application_id = vr_application_id AND e.element_id = l.element_id AND e.deleted = FALSE
		WHERE l.application_id = vr_application_id AND l.owner_id = vr_owner_id AND l.deleted = FALSE;
	ELSE
		RETURN QUERY
		SELECT e.element_id
		FROM fg_form_owners AS fo
			INNER JOIN fg_extended_form_elements AS e
			ON e.application_id = vr_application_id AND e.form_id = fo.form_id AND e.deleted = FALSE
		WHERE fo.application_id = vr_application_id AND fo.owner_id = vr_owner_id AND fo.deleted = FALSE;
	END IF;
END;
$$ LANGUAGE PLPGSQL;