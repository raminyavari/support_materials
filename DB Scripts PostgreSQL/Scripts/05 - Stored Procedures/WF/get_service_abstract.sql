DROP FUNCTION IF EXISTS wf_get_service_abstract;

CREATE OR REPLACE FUNCTION wf_get_service_abstract
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_node_type_id		UUID,
	vr_user_id			UUID,
	vr_null_tag_label 	VARCHAR(256)
)
RETURNS TABLE (
	tag		VARCHAR, 
	"count"	INTEGER
)
AS
$$
BEGIN
	vr_null_tag_label := gfn_verify_string(vr_null_tag_label);
	
	RETURN QUERY
	SELECT 	COALESCE(tg.tag, vr_null_tag_label) AS tag, 
			counts.cnt::INTEGER AS "count"
	FROM
		(
			SELECT 	owners.tag_id, 
					COUNT(owners.owner_id) AS cnt 
			FROM
				(
					SELECT 	"a".owner_id, 
							ws.tag_id
					FROM wf_history AS "a"
						INNER JOIN (
							SELECT 	h.owner_id, 
									MAX(h.id) AS "id"
							FROM wf_history AS h
							WHERE h.application_id = vr_application_id AND h.deleted = FALSE
							GROUP BY h.owner_id
						) AS b
						ON b.id = "a".id AND b.owner_id = "a".owner_id
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = "a".owner_id
						INNER JOIN wf_workflow_states AS ws
						ON ws.application_id = vr_application_id AND ws.state_id = "a".state_id
					WHERE a.application_id = vr_application_id AND
						(vr_workflow_id IS NULL OR 
							("a".workflow_id = vr_workflow_id AND ws.workflow_id = vr_workflow_id)
						) AND nd.node_type_id = vr_node_type_id AND nd.deleted = FALSE AND
						(vr_user_id IS NULL OR	
							EXISTS (
								SELECT 1
								FROM cn_node_creators AS nc
								WHERE nc.application_id = vr_application_id AND 
									nc.node_id = "a".owner_id AND nc.user_id = vr_user_id AND nc.deleted = FALSE
								LIMIT 1
							)
						)
				) AS owners
			GROUP BY owners.tag_id
		) AS counts
		LEFT JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = counts.tag_id;
END;
$$ LANGUAGE plpgsql;

