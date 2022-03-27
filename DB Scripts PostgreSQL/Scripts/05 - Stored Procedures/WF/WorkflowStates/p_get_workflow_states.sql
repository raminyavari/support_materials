DROP FUNCTION IF EXISTS wf_p_get_workflow_states;

CREATE OR REPLACE FUNCTION wf_p_get_workflow_states
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_state_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_workflow_state_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT wfs.id,
		   wfs.state_id,
		   wfs.workflow_id,
		   wfs.description,
		   tg.tag,
		   wfs.data_needs_type,
		   wfs.ref_data_needs_state_id,
		   wfs.data_needs_description,
		   wfs.description_needed,
		   wfs.hide_owner_name,
		   wfs.edit_permission,
		   wfs.response_type,
		   wfs.ref_state_id,
		   wfs.node_id,
		   nd.node_name,
		   nd.node_type_id,
		   nd.type_name AS node_type,
		   wfs.admin,
		   wfs.free_data_need_requests,
		   wfs.max_allowed_rejections,
		   wfs.rejection_title,
		   wfs.rejection_ref_state_id,
		   rs.title AS rejection_ref_state_title,
		   pl.poll_id,
		   pl.name AS poll_name,
		   vr_total_count
	FROM UNNEST(vr_state_ids) AS x
		INNER JOIN wf_workflow_states AS wfs
		ON wfs.state_id = x
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = wfs.node_id AND nd.deleted = FALSE
		LEFT JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = wfs.tag_id
		LEFT JOIN wf_states AS rs
		ON rs.application_id = vr_application_id AND rs.state_id = wfs.rejection_ref_state_id
		LEFT JOIN fg_polls AS pl
		ON pl.application_id = vr_application_id AND pl.poll_id = wfs.poll_id
	WHERE wfs.application_id = vr_application_id AND wfs.workflow_id = vr_workflow_id;
END;
$$ LANGUAGE plpgsql;

