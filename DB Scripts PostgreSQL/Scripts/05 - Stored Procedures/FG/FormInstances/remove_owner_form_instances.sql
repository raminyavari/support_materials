DROP FUNCTION IF EXISTS fg_remove_owner_form_instances;

CREATE OR REPLACE FUNCTION fg_remove_owner_form_instances
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_form_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT i.instance_id
		FROM fg_form_instances AS i
		WHERE i.application_id = vr_application_id AND i.form_id = vr_form_id AND 
			i.owner_id = vr_owner_id AND i.deleted = FALSE
	);

	RETURN fg_p_remove_form_instances(vr_application_id, vr_ids, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;

