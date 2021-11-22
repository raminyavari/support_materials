DROP FUNCTION IF EXISTS kw_p_get_history_by_ids;

CREATE OR REPLACE FUNCTION kw_p_get_history_by_ids
(
	vr_application_id	UUID,
	vr_ids				BIGINT[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF kw_history_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT	h.id,
			h.knowledge_id,
			h.action,
			h.text_options,
			h.description,
			h.actor_user_id,
			un.username AS actor_username,
			un.first_name AS actor_first_name,
			un.last_name AS actor_last_name,
			h.deputy_user_id,
			dn.username AS deputy_username,
			dn.first_name AS deputy_first_name,
			dn.last_name AS deputy_last_name,
			h.action_date,
			h.reply_to_history_id,
			h.wf_version_id,
			CASE WHEN nd.creator_user_id = h.actor_user_id THEN TRUE ELSE FALSE END::BOOLEAN AS is_creator,
			COALESCE((
				SELECT TRUE
				FROM cn_node_creators AS nc
				WHERE nc.application_id = vr_application_id AND nc.node_id = h.knowledge_id AND 
					nc.user_id = h.actor_user_id AND nc.deleted = FALSE
				LIMIT 1
			), FALSE)::BOOLEAN AS is_contributor,
			vr_total_count
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf("id", seq)
		INNER JOIN kw_history AS h
		ON h.application_id = vr_application_id AND h.id = rf.id
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = h.knowledge_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = h.actor_user_id
		LEFT JOIN users_normal AS dn
		ON dn.application_id = vr_application_id AND dn.user_id = h.deputy_user_id
	ORDER BY rf.seq ASC;
END;
$$ LANGUAGE plpgsql;

