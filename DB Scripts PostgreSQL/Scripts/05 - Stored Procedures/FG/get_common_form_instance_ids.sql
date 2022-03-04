DROP FUNCTION IF EXISTS fg_get_common_form_instance_ids;

CREATE OR REPLACE FUNCTION fg_get_common_form_instance_ids
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_filled_owner_id	UUID,
	vr_has_limit	 	BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT fi.instance_id AS "id"
	FROM fg_form_instances AS fi
		INNER JOIN (
			SELECT rf.form_id
			FROM (
					SELECT fo.form_id, COUNT(el.element_id) AS cnt
					FROM fg_form_owners AS fo
						LEFT JOIN fg_element_limits AS el
						INNER JOIN fg_extended_form_elements AS efe
						ON efe.application_id = vr_application_id AND efe.element_id = el.element_id
						ON el.application_id = vr_application_id AND 
							el.owner_id = fo.owner_id AND efe.form_id = fo.form_id AND el.deleted = FALSE
					WHERE fo.application_id = vr_application_id AND 
						fo.owner_id = vr_owner_id AND fo.deleted = FALSE
					GROUP BY fo.form_id
				) AS rf
			WHERE COALESCE(vr_has_limit, FALSE)::BOOLEAN = FALSE OR rf.cnt > 0
		) AS fid
		ON fi.form_id = fid.form_id
	WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_filled_owner_id;
END;
$$ LANGUAGE plpgsql;

