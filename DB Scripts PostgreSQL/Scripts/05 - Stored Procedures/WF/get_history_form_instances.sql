DROP FUNCTION IF EXISTS wf_get_history_form_instances;

CREATE OR REPLACE FUNCTION wf_get_history_form_instances
(
	vr_application_id	UUID,
	vr_history_ids		guid_table_type[],
	vr_selected	 		BOOLEAN
)
RETURNS TABLE (
	history_id		UUID,
	out_state_id	UUID,
	forms_id		UUID
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	IF vr_selected = FALSE THEN 
		vr_selected := NULL;
	END IF;

	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_history_ids) AS x
	);

	RETURN QUERY
	SELECT hfi.history_id,
		   hfi.out_state_id,
		   hfi.forms_id
	FROM UNNEST(vr_ids) AS x
		INNER JOIN wf_history AS hs
		ON hs.application_id = vr_application_id AND hs.history_id = x
		INNER JOIN wf_history_form_instances AS hfi
		ON hfi.application_id = vr_application_id AND hfi.history_id = hs.history_id
	WHERE (vr_selected IS NULL OR 
		(hs.selected_out_state_id IS NOT NULL AND hs.selected_out_state_id = hfi.out_state_id)) AND
		hs.deleted = FALSE AND hfi.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

