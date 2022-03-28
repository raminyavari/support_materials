DROP FUNCTION IF EXISTS wf_get_next_state_params;

CREATE OR REPLACE FUNCTION wf_get_next_state_params
(
	vr_application_id	UUID,
	vr_node_id			UUID,
    vr_workflow_id		UUID
)
RETURNS VARCHAR
AS
$$
DECLARE
	vr_start_state_id 	UUID;
	vr_response_type 	VARCHAR(20);
	vr_director_node_id UUID;
	vr_director_user_id UUID;
	vr_start_state_ids	UUID[];
BEGIN
	vr_start_state_ids := ARRAY(
		SELECT wfs.state_id
		FROM wf_workflow_states AS wfs
		WHERE wfs.application_id = vr_application_id AND 
			wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE AND
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
		
	vr_start_state_id := (
		SELECT rf.value 
		FROM UNNEST(vr_start_state_ids) AS rf
		LIMIT 1
	);
		
	SELECT 	s.response_type,
			s.node_id
	INTO	vr_response_type,
			vr_director_node_id
	FROM wf_workflow_states AS s
	WHERE s.application_id = vr_application_id AND s.workflow_id = vr_workflow_id AND 
		s.state_id = vr_start_state_id AND s.deleted = FALSE
	LIMIT 1;
	
	IF vr_response_type = 'SendToOwner' THEN
		vr_director_node_id := NULL;
		
		vr_director_user_id := (
			SELECT nd.creator_user_id 
			FROM cn_nodes AS nd 
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
			LIMIT 1
		);
	ELSEIF vr_response_type = 'RefState' THEN
		vr_director_node_id := NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;

