DROP FUNCTION IF EXISTS fg_p_remove_form_instances;

CREATE OR REPLACE FUNCTION fg_p_remove_form_instances
(
	vr_application_id	UUID,
	vr_instance_ids		UUID[],
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE FI
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_instance_ids) AS x
		INNER JOIN fg_form_instances AS fi
		ON fi.instance_id = x
	WHERE fi.application_id = vr_application_id AND fi.deleted = FALSE;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

