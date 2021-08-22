DROP FUNCTION IF EXISTS fg_fn_get_owner_form_instance_ids;

CREATE OR REPLACE FUNCTION fg_fn_get_owner_form_instance_ids
(
	vr_application_id	UUID,
	vr_owner_ids		UUID[],
	vr_form_id			UUID,
	vr_is_temporary 	BOOLEAN,
	vr_creator_user_id	UUID
)
RETURNS TABLE (
	owner_id 	UUID,
	instance_id UUID
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT fi.owner_id, fi.instance_id
	FROM (
			SELECT x.owner_id, x.form_id
			FROM (
					SELECT	"id" AS owner_id,
							CASE WHEN MAX(nd.name) IS NULL THEN FALSE ELSE TRUE END AS is_node,
							COALESCE(vr_form_id, MAX(f.form_id::VARCHAR(50))::UUID) AS form_id,
							CASE WHEN vr_form_id IS NULL AND MAX(e.extension) IS NULL THEN FALSE ELSE TRUE END AS has_form
					FROM UNNEST(vr_owner_ids) AS "id"
						LEFT JOIN cn_nodes AS nd
						ON vr_form_id IS NULL AND nd.application_id = vr_application_id AND nd.node_id = "id"
						LEFT JOIN fg_form_owners AS f
						ON vr_form_id IS NULL AND f.application_id = vr_application_id AND 
							f.owner_id = nd.node_type_id AND f.deleted = FALSE
						LEFT JOIN cn_extensions AS e
						ON vr_form_id IS NULL AND e.application_id = vr_application_id AND 
							e.owner_id = nd.node_type_id AND e.extension = 'Form' AND e.deleted = FALSE
					GROUP BY "id"
				) AS x
			WHERE (x.form_id IS NOT NULL AND x.has_form = TRUE) OR x.is_node = FALSE
		) AS external_ids
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.owner_id = external_ids.owner_id AND
			(external_ids.form_id IS NULL OR fi.form_id = external_ids.form_id) AND fi.deleted = FALSE AND
			(vr_is_temporary IS NULL OR COALESCE(fi.is_temporary, FALSE) = vr_is_temporary) AND
			(vr_creator_user_id IS NULL OR fi.creator_user_id = vr_creator_user_id);
END;
$$ LANGUAGE PLPGSQL;