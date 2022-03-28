DROP FUNCTION IF EXISTS wf_p_start_new_workflow;

CREATE OR REPLACE FUNCTION wf_p_start_new_workflow
(
	vr_application_id	UUID,
	vr_node_id			UUID,
    vr_workflow_id		UUID,
    vr_director_node_id	UUID,
	vr_director_user_id	UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP,
	OUT "result"	 	INTEGER,
	OUT "message"		VARCHAR(500),
	OUT	dashboards		REFCURSOR
)
AS
$$
DECLARE
	vr_terminated 			BOOLEAN;
	vr_previous_history_id	UUID;
	vr_start_state_id 		UUID;
	vr_response_type 		VARCHAR(20);
	vr_start_state_ids 		UUID[];
	vr_history_id	 		UUID;
	vr_state_title 			VARCHAR(1000);
	vr_hide_contributors 	BOOLEAN;
BEGIN
	SELECT 	h.terminated,
			h.history_id
	INTO	vr_terminated,
			vr_previous_history_id
	FROM wf_history AS h
	WHERE h.application_id = vr_application_id AND 
		h.owner_id = vr_node_id AND h.deleted = FALSE
	ORDER BY h.id DESC
	LIMIT 1;
	
	IF vr_terminated = FALSE THEN -- If result is null or equals 1, workflow doesn't exist or has been terminated
		SELECT 	-1::INTEGER,
				'TheNodeIsAlreadyInWorkFlow'
		INTO	"result",
				"message";
				
		RETURN;
	END IF;
	
	vr_start_state_ids := ARRAY(
		SELECT wfs.state_id
		FROM wf_workflow_states AS wfs
		WHERE wfs.application_id = vr_application_id AND wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE AND
			NOT EXISTS (
				SELECT 1
				FROM wf_state_connections AS sc
					INNER JOIN wf_workflow_states AS rf
					ON rf.application_id = vr_application_id AND rf.state_id = sc.in_state_id
				WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
					sc.out_state_id = wfs.state_id AND sc.deleted = FALSE AND rf.deleted = FALSE
				LIMIT 1
			)
	);
		
	IF COALESCE(ARRAY_LENGTH(vr_start_state_ids, 1), 0) <> 1 THEN
		SELECT 	-1::INTEGER,
				'WorkFlowStateNotFound'
		INTO	"result",
				"message";

		RETURN;
	ELSE
		vr_start_state_id := (
			SELECT rf.value 
			FROM UNNEST(vr_start_state_ids) AS rf
			LIMIT 1
		);
	END IF;
	
	vr_history_id := gen_random_uuid();
	
	INSERT INTO wf_history (
		application_id,
		history_id,
		owner_id,
		workflow_id,
		state_id,
		previous_history_id,
		director_node_id,
		director_user_id,
		rejected,
		terminated,
		sender_user_id,
		send_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_history_id,
		vr_node_id,
		vr_workflow_id,
		vr_start_state_id,
		vr_previous_history_id,
		vr_director_node_id,
		vr_director_user_id,
		FALSE,
		FALSE,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS "result" := ROW_COUNT;
	
	IF "result" <= 0 THEN
		SELECT 	-1::INTEGER,
				NULL::VARCHAR
		INTO	"result",
				"message";
		
		RETURN;
	END IF;
	
	-- Update WFState in CN_Nodes Table
	SELECT 	s.title 
	INTO	vr_state_title
	FROM wf_states AS s
	WHERE s.application_id = vr_application_id AND s.state_id = vr_start_state_id
	LIMIT 1;
	
	SELECT 	COALESCE(s.hide_owner_name, FALSE)::BOOLEAN
	INTO	vr_hide_contributors
	FROM wf_workflow_states AS s
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_start_state_id
	LIMIT 1;
	
	"result" := cn_p_modify_node_wf_state(vr_application_id, vr_node_id, vr_state_title, 
										   vr_hide_contributors, vr_current_user_id, vr_now);
	
	IF "result" <= 0 THEN
		SELECT 	-1::INTEGER,
				'StatusUpdateFailed'
		INTO	"result",
				"message";
		
		RETURN;
	END IF;
	-- end of Update WFState in CN_Nodes Table
	
	-- Send Dashboards
	SELECT 	x.result,
			x.dashboards
	INTO	"result",
			dashboards
	FROM wf_p_send_dashboards(vr_application_id, vr_history_id, vr_node_id, vr_workflow_id, 
							  vr_start_state_id, vr_director_user_id, vr_director_node_id, NULL, vr_now) AS x;
	
	IF "result" <= 0 THEN
		SELECT 	-1::INTEGER,
				'CannotDetermineDirector'
		INTO	"result",
				"message";
		
		RETURN;
	END IF;
	-- end of Send Dashboards
END;
$$ LANGUAGE plpgsql;

