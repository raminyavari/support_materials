DROP FUNCTION IF EXISTS wf_get_state_data_need_instances;

CREATE OR REPLACE FUNCTION wf_get_state_data_need_instances
(
	vr_application_id	UUID,
    vr_history_ids		guid_table_type[]
)
RETURNS SETOF wf_state_data_need_instance_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT sdni.instance_id
		FROM UNNEST(vr_history_ids) AS x
			INNER JOIN wf_state_data_need_instances AS sdni
			ON sdni.history_id = x.value
		WHERE sdni.application_id = vr_application_id AND sdni.deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM wf_p_get_state_data_need_instances(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

