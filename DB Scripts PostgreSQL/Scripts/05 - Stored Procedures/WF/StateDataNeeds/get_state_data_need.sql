DROP FUNCTION IF EXISTS wf_get_state_data_need;

CREATE OR REPLACE FUNCTION wf_get_state_data_need
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_state_id			UUID,
	vr_node_type_id		UUID
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
			SELECT ROW(vr_workflow_id, vr_state_id, vr_node_type_id)::guid_triple_table_type
		)
	);
END;
$$ LANGUAGE plpgsql;

