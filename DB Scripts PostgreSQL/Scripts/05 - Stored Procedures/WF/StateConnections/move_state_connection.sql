DROP FUNCTION IF EXISTS wf_move_state_connection;

CREATE OR REPLACE FUNCTION wf_move_state_connection
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_id		UUID,
	vr_out_state_id		UUID,
	vr_move_down	 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_sequence_no				INTEGER;
	vr_other_out_state_id 		UUID;
	vr_other_sequence_number 	INTEGER;
	vr_result					INTEGER;
BEGIN
	vr_sequence_no := (
		SELECT sc.sequence_number
		FROM wf_state_connections AS sc
		WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
			sc.in_state_id = vr_in_state_id AND sc.out_state_id = vr_out_state_id
		LIMIT 1
	);
	
	IF vr_move_down = TRUE THEN
		SELECT INTO vr_other_out_state_id, vr_other_sequence_number
					sc.out_state_id, sc.sequence_number
		FROM wf_state_connections AS sc
		WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
			sc.in_state_id = vr_in_state_id AND sc.sequence_number > vr_sequence_no
		ORDER BY sc.sequence_number ASC
		LIMIT 1;
	ELSE
		SELECT INTO vr_other_out_state_id, vr_other_sequence_number
					sc.out_state_id, sc.sequence_number
		FROM wf_state_connections AS sc
		WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
			sc.in_state_id = vr_in_state_id AND sc.sequence_number < vr_sequence_no
		ORDER BY sc.sequence_number DESC
		LIMIT 1;
	END IF;
	
	IF vr_other_out_state_id IS NULL THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	UPDATE wf_state_connections AS sc
	SET sequence_number = vr_other_sequence_number
	WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
		sc.in_state_id = vr_in_state_id AND sc.out_state_id = vr_out_state_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	UPDATE wf_state_connections AS sc
	SET sequence_number = vr_sequence_no
	WHERE sc.application_id = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
		sc.in_state_id = vr_in_state_id AND sc.out_state_id = vr_other_out_state_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

