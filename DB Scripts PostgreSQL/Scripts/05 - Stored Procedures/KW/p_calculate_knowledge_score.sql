DROP FUNCTION IF EXISTS kw_p_calculate_knowledge_score;

CREATE OR REPLACE FUNCTION kw_p_calculate_knowledge_score
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_date_from	TIMESTAMP;
	vr_score 		FLOAT DEFAULT 0;
	vr_result		INTEGER;
BEGIN
	vr_date_from := (
		SELECT MIN(h.action_date)
		FROM kw_history AS h
		WHERE h.application_id = vr_application_id AND
			h.knowledge_id = vr_knowledge_id AND h.action = 'SendToAdmin'
	);
	
	IF EXISTS(
		SELECT 1
		FROM kw_question_answers AS qa
			LEFT JOIN cn_nodes AS nd
			INNER JOIN kw_type_questions AS tq
			ON tq.application_id = vr_application_id AND 
				tq.knowledge_type_id = nd.node_type_id AND tq.deleted = FALSE
			ON nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id AND
				nd.node_id = qa.knowledge_id
		WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_knowledge_id AND 
			qa.deleted = FALSE AND (tq.weight IS NULL OR tq.weight <= 0)
		LIMIT 1
	) THEN
		SELECT vr_score = SUM(rf.score)::FLOAT / COALESCE(COUNT(rf.user_id), 1)::FLOAT
		FROM (
				SELECT	qa.user_id, 
						SUM(COALESCE(COALESCE(qa.admin_score, qa.score), 0))::FLOAT / 
							COALESCE(COUNT(qa.question_id), 1)::FLOAT AS score
				FROM kw_question_answers AS qa
				WHERE qa.application_id = vr_application_id AND 
					qa.knowledge_id = vr_knowledge_id AND qa.deleted = FALSE AND
					(vr_date_from IS NULL OR qa.evaluation_date >= vr_date_from)
				GROUP BY qa.user_id
			) AS rf
		LIMIT 1;
	ELSE
		SELECT vr_score = SUM(rf.score)::FLOAT / COALESCE(COUNT(rf.user_id), 1)::FLOAT
		FROM (
				SELECT	qa.user_id,
						SUM((tq.weight * COALESCE(COALESCE(qa.admin_score, qa.score), 0)))::FLOAT / 
							SUM(tq.weight)::FLOAT AS score
				FROM kw_question_answers AS qa
					INNER JOIN cn_nodes AS nd
					INNER JOIN kw_type_questions AS tq
					ON tq.application_id = vr_application_id AND 
						tq.knowledge_type_id = nd.node_type_id AND tq.deleted = FALSE
					ON nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id AND
						nd.node_id = qa.knowledge_id
				WHERE qa.application_id = vr_application_id AND 
					qa.knowledge_id = vr_knowledge_id AND qa.deleted = FALSE AND
					(vr_date_from IS NULL OR qa.evaluation_date >= vr_date_from)
				GROUP BY qa.user_id
			) AS rf
		LIMIT 1;
	END IF;
	
	UPDATE cn_nodes AS nd
	SET score = vr_score
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

