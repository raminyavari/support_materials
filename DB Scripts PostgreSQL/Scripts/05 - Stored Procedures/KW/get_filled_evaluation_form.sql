DROP FUNCTION IF EXISTS kw_get_filled_evaluation_form;

CREATE OR REPLACE FUNCTION kw_get_filled_evaluation_form
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID,
    vr_user_id			UUID,
    vr_wf_version_id	INTEGER
)
RETURNS TABLE (
	question_id		UUID,
	title			VARCHAR,
	text_value		VARCHAR,
	score			FLOAT,
	evaluation_date	TIMESTAMP
)
AS
$$
DECLARE
	vr_score_scale			INTEGER;
	vr_coeff 				FLOAT;
	vr_last_wf_version_id	INTEGER;
BEGIN
	vr_score_scale := (
		SELECT kt.score_scale
		FROM cn_nodes AS nd
			INNER JOIN kw_knowledge_types AS kt
			ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_knowledge_id
		LIMIT 1
	);
	
	vr_coeff := COALESCE(vr_score_scale, 10)::FLOAT / 10::FLOAT;
	
	vr_last_wf_version_id := kw_fn_get_wf_version_id(vr_application_id, vr_knowledge_id);
	
	IF vr_wf_version_id IS NULL OR vr_wf_version_id = vr_last_wf_version_id THEN
		RETURN QUERY
		SELECT	qa.question_id,
				qa.title,
				o.title AS text_value,
				COALESCE(qa.admin_score, qa.score) * vr_coeff AS score,
				qa.evaluation_date
		FROM kw_question_answers AS qa
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = qa.knowledge_id
			LEFT JOIN kw_answer_options AS o
			ON o.application_id = vr_application_id AND o.id = qa.selected_option_id
			LEFT JOIN kw_type_questions AS q
			ON q.application_id = vr_application_id AND 
				q.knowledge_type_id = nd.node_type_id AND q.question_id = qa.question_id
		WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_knowledge_id AND 
			qa.user_id = vr_user_id AND qa.deleted = FALSE
		ORDER BY q.sequence_number ASC;
	ELSE
		RETURN QUERY
		SELECT	qa.question_id,
				qa.title,
				o.title AS text_value,
				COALESCE(qa.admin_score, qa.score) * vr_coeff AS score,
				qa.evaluation_date
		FROM kw_question_answers_history AS qa
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = qa.knowledge_id
			LEFT JOIN kw_answer_options AS o
			ON o.application_id = vr_application_id AND o.id = qa.selected_option_id
			LEFT JOIN kw_type_questions AS q
			ON q.application_id = vr_application_id AND 
				q.knowledge_type_id = nd.node_type_id AND q.question_id = qa.question_id
		WHERE qa.application_id = vr_application_id AND qa.knowledge_id = vr_knowledge_id AND 
			qa.user_id = vr_user_id AND qa.deleted = FALSE AND qa.wf_version_id = vr_wf_version_id
		ORDER BY q.sequence_number ASC;
	END IF;
END;
$$ LANGUAGE plpgsql;

