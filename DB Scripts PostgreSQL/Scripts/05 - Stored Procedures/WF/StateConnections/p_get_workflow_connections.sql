DROP FUNCTION IF EXISTS wf_p_get_workflow_connections;

CREATE OR REPLACE FUNCTION wf_p_get_workflow_connections
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_connection_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT sc.id,
		   sc.workflow_id,
		   sc.in_state_id,
		   sc.out_state_id,
		   sc.sequence_number,
		   sc.label AS connection_label,
		   sc.attachment_required,
		   sc.attachment_title,
		   sc.node_required,
		   sc.node_type_id,
		   nt.name AS node_type,
		   sc.node_type_description,
		   vr_total_count
	FROM UNNEST(vr_in_state_ids) AS x
		INNER JOIN wf_state_connections AS sc
		ON sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND
			sc.in_state_id = x AND sc.deleted = FALSE
		INNER JOIN wf_states AS s
		ON s.application_id = vr_application_id AND s.state_id = sc.out_state_id AND s.deleted = FALSE
		LEFT JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = sc.node_type_id
	ORDER BY COALESCE(sc.sequence_number, 1000000) ASC, sc.creation_date ASC;
END;
$$ LANGUAGE plpgsql;

