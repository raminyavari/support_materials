DROP FUNCTION IF EXISTS fg_get_owner_form_instances;

CREATE OR REPLACE FUNCTION fg_get_owner_form_instances
(
	vr_application_id	UUID,
	vr_owner_ids		guid_table_type[],
	vr_form_id			UUID,
	vr_is_temporary 	BOOLEAN,
	vr_creator_user_id	UUID
)
RETURNS SETOF fg_form_instance_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_owner_ids) AS x
	);
	
	RETURN QUERY
	SELECT *
	FROM fg_p_get_owner_form_instances(vr_application_id, vr_ids, vr_form_id, vr_is_temporary, vr_creator_user_id);
END;
$$ LANGUAGE plpgsql;

