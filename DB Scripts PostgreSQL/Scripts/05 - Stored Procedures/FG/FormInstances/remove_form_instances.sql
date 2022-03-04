DROP FUNCTION IF EXISTS fg_remove_form_instances;

CREATE OR REPLACE FUNCTION fg_remove_form_instances
(
	vr_application_id	UUID,
	vr_instance_ids		guid_table_type[],
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN fg_p_remove_form_instances(
		vr_application_id, 
		ARRAY(
			SELECT DISTINCT x.value
			FROM UNNEST(vr_instance_ids) AS x
		), 
		vr_current_user_id, 
		vr_now);
END;
$$ LANGUAGE plpgsql;

