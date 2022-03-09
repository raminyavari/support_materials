DROP FUNCTION IF EXISTS ntfn_p_get_owner_message_templates;

CREATE OR REPLACE FUNCTION ntfn_p_get_owner_message_templates
(
	vr_application_id	UUID,
	vr_owner_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF ntfn_message_template_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT mt.template_id,
		   mt.owner_id,
		   mt.body_text,
		   mt.audience_type,
		   mt.audience_ref_owner_id,
		   mt.audience_node_id,
		   nd.node_name AS audience_node_name,
		   nd.node_type_id AS audience_node_type_id,
		   nd.type_name AS audience_node_type,
		   mt.audience_node_admin,
		   vr_total_count
	FROM UNNEST(vr_owner_ids) AS rf
		INNER JOIN ntfn_message_templates AS mt
		ON mt.owner_id = rf
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = mt.audience_node_id
	WHERE mt.application_id = vr_application_id AND mt.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

