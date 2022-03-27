DROP FUNCTION IF EXISTS wf_p_get_state_data_need_instances;

CREATE OR REPLACE FUNCTION wf_p_get_state_data_need_instances
(
	vr_application_id	UUID,
    vr_instance_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_state_data_need_instance_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT sdni.instance_id,
		   sdni.history_id,
		   sdni.node_id,
		   nd.node_name,
		   nd.node_type_id,
		   sdni.filled,
		   sdni.filling_date,
		   sdni.attachment_id,
		   vr_total_count
	FROM UNNEST(vr_instance_ids) AS x
		INNER JOIN wf_state_data_need_instances AS sdni
		ON sdni.instance_id = x
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = sdni.node_id
	WHERE sdni.application_id = vr_application_id AND sdni.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

