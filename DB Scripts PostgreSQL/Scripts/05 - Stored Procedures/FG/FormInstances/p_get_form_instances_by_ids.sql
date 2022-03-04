DROP FUNCTION IF EXISTS fg_p_get_form_instances_by_ids;

CREATE OR REPLACE FUNCTION fg_p_get_form_instances_by_ids
(
	vr_application_id	UUID,
	vr_instance_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF fg_form_instance_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	RETURN QUERY
	SELECT fi.instance_id,
		   fi.form_id,
		   fi.owner_id,
		   fi.director_id,
		   fi.filled,
		   fi.filling_date,
		   ef.title AS form_title,
		   ef.description,
		   fi.creator_user_id,
		   un.username AS creator_username,
		   un.first_name AS creator_first_name,
		   un.last_name AS creator_last_name,
		   vr_total_count AS total_count
	FROM UNNEST(vr_instance_ids) AS x
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = x
		INNER JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = fi.form_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = fi.creator_user_id;
END;
$$ LANGUAGE plpgsql;

