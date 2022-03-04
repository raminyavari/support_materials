DROP FUNCTION IF EXISTS fg_get_owner_form;

CREATE OR REPLACE FUNCTION fg_get_owner_form
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS SETOF fg_form_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM fg_p_get_forms_by_ids(
			vr_application_id, 
			ARRAY(
				SELECT o.form_id
				FROM fg_form_owners AS o
				WHERE o.application_id = vr_application_id AND 
					o.owner_id = vr_owner_id AND o.deleted = FALSE
			)
		);
END;
$$ LANGUAGE plpgsql;

