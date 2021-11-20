DROP FUNCTION IF EXISTS kw_p_auto_set_knowledge_status;

CREATE OR REPLACE FUNCTION kw_p_auto_set_knowledge_status
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_now				TIMESTAMP
)
RETURNS TABLE (
	"result"				INTEGER,
	accepted				BOOLEAN,
	searchability_activated	BOOLEAN
)
AS
$$
DECLARE
	vr_evaluators_count 		INTEGER; 
	vr_cur_evaluators_count 	INTEGER;
	vr_min_evaluators_count 	INTEGER;
	vr_status 					VARCHAR(50);
	vr_score 					FLOAT;
	vr_acceptable 				BOOLEAN;
	vr_is_searchable 			BOOLEAN;

	vr_result					INTEGER DEFAULT 0;
	vr_accepted					BOOLEAN DEFAULT FALSE;
	vr_searchability_activated	BOOLEAN DEFAULT FALSE;
BEGIN
	vr_evaluators_count := ntfn_p_get_dashboards_count(vr_application_id, NULL, vr_node_id, NULL, 
													   'Knowledge', 'Evaluator');

	SELECT vr_min_evaluators_count = kt.min_evaluations_count
	FROM cn_nodes AS nd
		INNER JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	vr_cur_evaluators_count := COALESCE((
		SELECT COUNT(DISTINCT qa.user_id)
		FROM kw_question_answers AS qa
		WHERE qa.application_id = vr_application_id AND 
			qa.knowledge_id = vr_node_id AND qa.deleted = FALSE
		GROUP BY qa.user_id
		LIMIT 1
	), 0)::INTEGER;
	
	IF COALESCE(vr_min_evaluators_count, 0) <= 0 OR 
		vr_min_evaluators_count > (vr_evaluators_count + vr_cur_evaluators_count) THEN
		vr_min_evaluators_count := vr_evaluators_count + vr_cur_evaluators_count;
	END IF;
	
	IF vr_cur_evaluators_count >= vr_min_evaluators_count THEN
		vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, vr_node_id, NULL, 'Knowledge', NULL);
			
		IF vr_result <= 0 THEN
			RETURN QUERY
			SELECT -1::INTEGER, FALSE, FALSE;
		END IF;
	
		SELECT	vr_status = nd.status, 
				vr_score = nd.score
		FROM cn_nodes AS nd 
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		LIMIT 1;
		
		vr_acceptable := (
			SELECT 	CASE
						WHEN COALESCE(vr_score, 0) >= (
								(COALESCE(kt.min_acceptable_score, 0) * 10)::FLOAT / 
								COALESCE(CASE WHEN kt.score_scale = 0 THEN 1 ELSE kt.score_scale END, 1)::FLOAT
							) THEN TRUE
						ELSE FALSE
					END
			FROM cn_nodes AS nd
				INNER JOIN kw_knowledge_types AS kt
				ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
			LIMIT 1
		);
		
		IF (vr_acceptable = TRUE AND vr_status <> 'Accepted') OR 
			(COALESCE(vr_acceptable, FALSE) = FALSE AND vr_st <> 'Rejected') THEN
			UPDATE cn_nodes AS nd
			SET status = CASE WHEN vr_acceptable = TRUE THEN 'Accepted' ELSE 'Rejected' END,
				publication_date = vr_now
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
			
			IF vr_acceptable = TRUE THEN
				vr_accepted = TRUE;
			END IF;
		END IF;
		
		vr_is_searchable := (
			SELECT nd.searchable
			FROM cn_nodes AS nd 
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
			LIMIT 1
		);
		
		IF COALESCE(vr_is_searchable, FALSE) = FALSE AND vr_accepted = TRUE THEN
			UPDATE cn_nodes AS nd
			SET searchable = TRUE
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
			
			vr_searchability_activated := TRUE;
		END IF;
	END IF;
	
	RETURN QUERY
	SELECT vr_result, vr_accepted, vr_searchability_activated;
END;
$$ LANGUAGE plpgsql;

