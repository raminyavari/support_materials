DROP FUNCTION IF EXISTS wf_p_get_history_by_ids;

CREATE OR REPLACE FUNCTION wf_p_get_history_by_ids
(
	vr_application_id	UUID,
	vr_history_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_history_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	h.history_id,
		   	h.previous_history_id,
			h.owner_id,
		   	h.workflow_id,
		   	h.director_node_id,
		   	h.director_user_id,
		   	n.node_name AS director_node_name,
		   	n.type_name AS director_node_type,
		   	h.state_id,
		   	s.title AS state_title,
		   	h.selected_out_state_id,
		   	h.description,
		   	h.actor_user_id AS sender_user_id,
		   	u.username AS sender_username,
		   	u.first_name AS sender_first_name,
		   	u.last_name AS sender_last_name,
		   	h.send_date,
		   	(
				SELECT "p".poll_id
				FROM fg_polls AS "p"
				WHERE "p".application_id = vr_application_id AND 
					"p".owner_id = h.history_id AND "p".deleted = FALSE
				ORDER BY "p".creation_date DESC
			   	LIMIT 1
		   	) AS poll_id,
		   	(
				SELECT rf.name
				FROM fg_polls AS "p"
					INNER JOIN fg_polls AS rf
					ON rf.application_id = vr_application_id AND rf.poll_id = "p".is_copy_of_poll_id
				WHERE "p".application_id = vr_application_id AND 
					"p".owner_id = h.history_id AND "p".deleted = FALSE
				ORDER BY "p".creation_date DESC
				LIMIT 1
		   	) AS poll_name,
			vr_total_count
	FROM UNNEST(vr_history_ids) AS x
		INNER JOIN wf_history AS h
		ON h.application_id = vr_application_id AND h.history_id = x
		INNER JOIN wf_states AS s
		ON s.application_id = vr_application_id AND s.state_id = h.state_id
		LEFT JOIN cn_view_nodes_normal AS n
		ON n.application_id = vr_application_id AND n.node_id = h.director_node_id
		LEFT JOIN users_normal AS u
		ON u.application_id = vr_application_id AND u.user_id = h.actor_user_id
	ORDER BY h.id DESC;
END;
$$ LANGUAGE plpgsql;

