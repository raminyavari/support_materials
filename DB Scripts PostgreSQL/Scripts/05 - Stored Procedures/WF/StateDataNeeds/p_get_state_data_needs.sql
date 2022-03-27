DROP FUNCTION IF EXISTS wf_p_get_state_data_needs;

CREATE OR REPLACE FUNCTION wf_p_get_state_data_needs
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_state_ids		UUID[]
)
RETURNS SETOF wf_state_data_need_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM wf_p_get_state_data_needs_by_ids(
		vr_application_id, 
		ARRAY(
			SELECT ROW(vr_workflow_id, sdn.state_id, sdn.node_type_id)::guid_triple_table_type
			FROM UNNEST(vr_state_ids) AS x
				INNER JOIN wf_state_data_needs AS sdn
				ON sdn.state_id = x
			WHERE sdn.application_id = vr_application_id AND 
				sdn.workflow_id = vr_workflow_id AND sdn.deleted = FALSE
		)
	);
END;
$$ LANGUAGE plpgsql;

