DROP FUNCTION IF EXISTS wf_get_workflow_state_items_count;

CREATE OR REPLACE FUNCTION wf_get_workflow_state_items_count
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_state_id			UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN ((
		SELECT COUNT(DISTINCT h.owner_id)
		FROM wf_history AS h
			INNER JOIN (
				SELECT 	"a".owner_id, 
						MAX("a".id) AS "id"
				FROM wf_history AS "a"
				WHERE "a".application_id = vr_application_id AND 
					"a".workflow_id = vr_workflow_id AND "a".deleted = FALSE
				GROUP BY "a".owner_id
			) AS x
			ON x.id = h.id
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = h.owner_id AND nd.deleted = FALSE
		WHERE h.application_id = vr_application_id AND h.state_id = vr_state_id
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

