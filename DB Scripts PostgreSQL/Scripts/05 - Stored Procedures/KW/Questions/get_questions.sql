DROP FUNCTION IF EXISTS kw_get_questions;

CREATE OR REPLACE FUNCTION kw_get_questions
(
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID
)
RETURNS TABLE (
	"id"				UUID, 
	knowledge_type_id	UUID, 
	question_id			UUID, 
	question_body		VARCHAR,
	related_node_id		UUID,
	related_node_name	VARCHAR,
	weight				FLOAT
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	tq.id, 
			tq.knowledge_type_id, 
			tq.question_id, 
			q.title AS question_body,
			nd.node_id AS related_node_id,
			nd.name AS related_node_name,
			tq.weight
	FROM kw_type_questions AS tq
		INNER JOIN kw_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = tq.question_id
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = tq.node_id
	WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND 
		(nd.node_id IS NULL OR nd.deleted = FALSE) AND tq.deleted = FALSE
	ORDER BY tq.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;

