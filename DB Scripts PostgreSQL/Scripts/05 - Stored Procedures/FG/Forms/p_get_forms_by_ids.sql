DROP FUNCTION IF EXISTS fg_p_get_forms_by_ids;

CREATE OR REPLACE FUNCTION fg_p_get_forms_by_ids
(
	vr_application_id	UUID,
    vr_form_ids			UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF fg_form_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	ef.form_id,
	   		ef.title,
	   		ef.name,
	   		ef.description,
			vr_total_count AS total_count
	FROM UNNEST(vr_form_ids) AS x
		INNER JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = x
	ORDER BY ef.creation_date DESC;
END;
$$ LANGUAGE plpgsql;

