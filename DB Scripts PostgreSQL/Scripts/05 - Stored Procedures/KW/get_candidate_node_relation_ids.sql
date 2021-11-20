DROP FUNCTION IF EXISTS kw_get_candidate_node_relation_ids;

CREATE OR REPLACE FUNCTION kw_get_candidate_node_relation_ids
(
	vr_application_id						UUID,
	vr_knowledge_type_id_or_knowledge_id	UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	vr_knowledge_type_id_or_knowledge_id := COALESCE((
		SELECT nd.node_type_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_type_id_or_knowledge_id
		LIMIT 1
	), vr_knowledge_type_id_or_knowledge_id);
	
	RETURN QUERY
	SELECT cr.node_id AS "id"
	FROM kw_candidate_relations AS cr
	WHERE cr.application_id = vr_application_id AND 
		cr.knowledge_type_id = vr_knowledge_type_id_or_knowledge_id AND 
		cr.node_id IS NOT NULL AND cr.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

