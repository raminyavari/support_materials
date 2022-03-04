DROP FUNCTION IF EXISTS fg_create_form_instance;

CREATE OR REPLACE FUNCTION fg_create_form_instance
(
	vr_application_id	UUID,
	vr_instances		form_instance_table_type[],
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN fg_p_create_form_instance(vr_application_id, vr_instances, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;

