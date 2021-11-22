DROP FUNCTION IF EXISTS kw_save_evaluation_form;

CREATE OR REPLACE FUNCTION kw_save_evaluation_form
(
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_user_id				UUID,
    vr_current_user_id		UUID,
    vr_answers				guid_float_table_type[],
    vr_score				FLOAT,
    vr_evaluation_date	 	TIMESTAMP,
    vr_admin_user_ids		guid_table_type[],
    vr_text_options	 		VARCHAR(1000),
    vr_description	 		VARCHAR(2000)
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_devoluted				BOOLEAN DEFAULT FALSE;
	vr_uid 						UUID;
	vr_username 				VARCHAR(1000); 
	vr_first_name 				VARCHAR(1000); 
	vr_last_name 				VARCHAR(1000);
	vr_searchability_activated	BOOLEAN;
	vr_accepted 				BOOLEAN;
	vr_result					INTEGER;
	vr_status 					VARCHAR(100);
	vr_cursor_dash				REFCURSOR;
	vr_cursor_bool				REFCURSOR;
BEGIN
	DROP TABLE IF EXISTS vr_ans_43523;

	CREATE TEMP TABLE vr_ans_43523 (
		question_id UUID,
		score 		FLOAT, 
		"exists"	BOOLEAN
	);
		
	INSERT INTO vr_ans_43523 (question_id, score, "exists")
	SELECT 	rf.first_value, 
			rf.second_value, 
			CASE WHEN qa.knowledge_id IS NULL THEN FALSE ELSE TRUE END
	FROM UNNEST(vr_answers) AS rf
		LEFT JOIN kw_question_answers AS qa
		ON qa.application_id = vr_application_id AND qa.knowledge_id = vr_node_id AND 
			qa.user_id = vr_user_id AND qa.question_id = rf.first_value;
			
	IF vr_current_user_id IS NOT NULL AND vr_user_id IS NOT NULL AND vr_current_user_id <> vr_user_id THEN
		vr_devoluted := TRUE;
	END IF;
	
	UPDATE kw_question_answers
	SET title = q.title,
		score = CASE WHEN vr_devoluted = TRUE THEN qa.score ELSE rf.score END,
		admin_id = CASE WHEN vr_devoluted = TRUE THEN vr_current_user_id ELSE NULL END,
		admin_score = CASE WHEN vr_devoluted = TRUE THEN rf.score ELSE qa.admin_score END,
		evaluation_date = vr_evaluation_date,
		deleted = FALSE
	FROM UNNEST(vr_ans_43523) AS rf
		INNER JOIN kw_question_answers AS qa
		ON qa.question_id = rf.question_id
		INNER JOIN kw_questions AS q
		ON q.application_id = vr_application_id AND q.question_id = rf.question_id
	WHERE qa.application_id = vr_application_id AND rf.exists = TRUE AND 
		qa.knowledge_id = vr_node_id AND qa.user_id = vr_user_id;


	INSERT INTO kw_question_answers (
		application_id,
		knowledge_id,
		user_id,
		question_id,
		title,
		score,
		admin_id,
		admin_score,
		evaluation_date,
		deleted
	)
	SELECT	vr_application_id,
			vr_node_id, 
			vr_user_id, 
			rf.question_id, 
			q.title, 
			rf.score,
			CASE WHEN vr_devoluted = TRUE THEN vr_current_user_id ELSE NULL END,
			CASE WHEN vr_devoluted = TRUE THEN rf.score ELSE NULL END,
			vr_evaluation_date,
			FALSE
	FROM UNNEST(vr_ans_43523) AS rf
		INNER JOIN kw_questions AS q
		ON q.question_id = rf.question_id
	WHERE q.application_id = vr_application_id AND COALESCE(rf.exists, FALSE) = FALSE;
	
	
	-- Create history
	INSERT INTO kw_history(
		application_id,
		knowledge_id,
		"action",
		actor_user_id,
		action_date,
		deputy_user_id,
		text_options,
		description,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'Evaluation',
		vr_user_id,
		vr_evaluation_date,
		CASE WHEN vr_devoluted = TRUE THEN vr_current_user_id ELSE NULL END,
		vr_text_options,
		gfn_verify_string(vr_description),
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	);
	-- end of create history
	
	
	vr_result := kw_p_calculate_knowledge_score(vr_application_id, vr_node_id);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'ScoreCalculationFailed');
		RETURN;
	END IF;
	
	
	-- Set dashboard AS done
	vr_uid := COALESCE(vr_user_id, vr_current_user_id);
	
	SELECT	vr_username = un.username, 
			vr_first_name = un.first_name, 
			vr_last_name = un.last_name
	FROM users_normal AS un
	WHERE un.application_id = vr_application_id AND un.user_id = vr_uid
	LIMIT 1;
	
	vr_result := ntfn_p_set_dashboards_as_done(vr_application_id, vr_uid, vr_node_id, NULL, 
											   'Knowledge', 'Evaluator', vr_evaluation_date);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of set dashboard AS done
	
	
	SELECT 	vr_searchability_activated = x.searchability_activated, 
			vr_accepted = x.accepted, 
			vr_result = x.result
	FROM kw_p_auto_set_knowledge_status(vr_application_id, vr_node_id, vr_evaluation_date) AS x
	LIMIT 1;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'DeterminingKnowledgeStatusFailed');
		RETURN;
	END IF;
	
	
	-- Send new dashboards
	DROP TABLE IF EXISTS vr_dash_42957;
	
	CREATE TEMP TABLE vr_dash_42957 OF dashboard_table_type;
	
	INSERT INTO vr_dash_42957 (
		user_id, 
		node_id, 
		ref_item_id, 
		"type", 
		sub_type, 
		removable, 
		send_date,
		"info"
	)
	SELECT	x.value,
			vr_node_id,
			vr_node_id,
			'Knowledge',
			'EvaluationDone',
			TRUE,
			vr_evaluation_date,
			'{"UserID":"' || vr_uid::VARCHAR(50) || '"' ||
				',"UserName":"' || gfn_base64_encode(vr_username) || '"' ||
				',"FirstName":"' || gfn_base64_encode(vr_first_name) || '"' ||
				',"LastName":"' || gfn_base64_encode(vr_last_name) || '"' ||
			'}'
	FROM UNNEST(vr_admin_user_ids) AS x;
	
	vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
		SELECT d
		FROM vr_dash_42957 AS d
	));
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
	ELSE
		OPEN vr_cursor_dash FOR
		SELECT d.*
		FROM vr_dash_42957 AS d;
		
		RETURN NEXT vr_cursor_dash;
	END IF;
	-- end of send new dashboards
	
	
	SELECT vr_status = nd.status
	FROM cn_nodes AS nd 
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	LIMIT 1;
	
	OPEN vr_cursor_bool FOR
	SELECT 	1::INTEGER AS "result", 
			vr_accepted AS accepted, 
			vr_searchability_activated AS searchability_activated, 
			vr_status AS status;
		
	RETURN NEXT vr_cursor_bool;
END;
$$ LANGUAGE plpgsql;

