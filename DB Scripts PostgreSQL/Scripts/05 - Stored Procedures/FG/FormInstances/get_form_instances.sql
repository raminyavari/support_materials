DROP FUNCTION IF EXISTS fg_get_form_instances;

CREATE OR REPLACE FUNCTION fg_get_form_instances
(
	vr_application_id	UUID,
	vr_instance_ids		guid_table_type[]
)
RETURNS SETOF fg_form_instance_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_instance_ids) AS x
	);
	
	RETURN QUERY
	SELECT *
	FROM fg_p_get_form_instances_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

