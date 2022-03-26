DROP FUNCTION IF EXISTS wf_p_get_owner_auto_messages;

CREATE OR REPLACE FUNCTION wf_p_get_owner_auto_messages
(
	vr_application_id	UUID,
	vr_owner_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_auto_message_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT am.auto_message_id,
		   am.owner_id,
		   am.body_text,
		   am.audience_type,
		   am.ref_state_id,
		   st.title AS ref_state_title,
		   am.node_id,
		   nd.node_name,
		   nd.node_type_id,
		   nd.type_name AS node_type,
		   am.admin,
		   vr_total_count
	FROM UNNEST(vr_owner_ids) AS x
		INNER JOIN wf_auto_messages AS am
		ON am.owner_id = x
		LEFT JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = am.ref_state_id
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = am.node_id
	WHERE am.application_id = vr_application_id AND am.deleted = FALSE
	ORDER BY am.creation_date ASC;
END;
$$ LANGUAGE plpgsql;

