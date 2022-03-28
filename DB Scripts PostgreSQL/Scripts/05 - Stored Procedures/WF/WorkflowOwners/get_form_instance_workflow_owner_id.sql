DROP FUNCTION IF EXISTS wf_get_form_instance_workflow_owner_id;

CREATE OR REPLACE FUNCTION wf_get_form_instance_workflow_owner_id
(
	vr_application_id	UUID,
	vr_form_instance_id	UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT h.owner_id
		FROM fg_form_instances AS fi
			INNER JOIN wf_history_form_instances AS hfi
			ON hfi.application_id = vr_application_id AND hfi.forms_id = fi.owner_id
			INNER JOIN wf_history AS h
			ON h.application_id = vr_application_id AND h.history_id = hfi.history_id
		WHERE fi.application_id = vr_application_id AND fi.instance_id = vr_form_instance_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

