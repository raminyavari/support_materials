DROP FUNCTION IF EXISTS wf_p_get_state_data_needs_by_ids;

CREATE OR REPLACE FUNCTION wf_p_get_state_data_needs_by_ids
(
	vr_application_id	UUID,
	vr_ids				guid_triple_table_type[], -- first: workflow_id, second: state_id, third: node_type_id
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_state_data_need_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT sdn.id,
		   sdn.state_id,
		   sdn.workflow_id,
		   sdn.node_type_id,
		   ef.form_id,
		   ef.title AS form_title,
		   sdn.description,
		   nt.name AS node_type,
		   sdn.multiple_select AS multi_select,
		   sdn.admin,
		   sdn.necessary,
		   vr_total_count
	FROM UNNEST(vr_ids) AS external_ids
		INNER JOIN wf_state_data_needs AS sdn
		ON sdn.application_id = vr_application_id AND 
			sdn.workflow_id = external_ids.first_value AND
			sdn.state_id = external_ids.second_value AND 
			sdn.node_type_id = external_ids.third_value
		LEFT JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = sdn.node_type_id
		LEFT JOIN fg_form_owners AS fo
		INNER JOIN fg_extended_forms AS ef
		ON ef.application_id = vr_application_id AND ef.form_id = fo.form_id
		ON fo.application_id = vr_application_id AND fo.owner_id = sdn.id AND fo.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

