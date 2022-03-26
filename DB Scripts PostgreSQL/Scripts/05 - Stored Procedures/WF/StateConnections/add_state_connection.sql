DROP FUNCTION IF EXISTS wf_add_state_connection;

CREATE OR REPLACE FUNCTION wf_add_state_connection
(
	vr_application_id	UUID,
	vr_workflow_id		UUID,
	vr_in_state_id		UUID,
	vr_out_state_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS UUID
AS
$$
DECLARE
	vr_sequence_number	INTEGER;
	vr_id 				UUID;
BEGIN
	vr_sequence_number := (
		SELECT COALESCE(MAX(sc.sequence_number), 0)::INTEGER 
		FROM wf_state_connections AS sc
		WHERE sc.application_id = vr_application_id AND 
			sc.workflow_id = vr_workflow_id AND sc.in_state_id = vr_in_state_id
	) + 1::INTEGER;
	
	SELECT INTO vr_id
				sc.id
	FROM wf_state_connections AS sc
	WHERE sc.applicationID = vr_application_id AND sc.workflow_id = vr_workflow_id AND 
		sc.in_state_id = vr_in_state_id AND sc.out_state_id = vr_out_state_id AND sc.deleted = TRUE
	LIMIT 1;
	
	IF vr_id IS NOT NULL THEN
		UPDATE wf_state_connections AS sc
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE sc.application_id = vr_application_id AND sc.id = vr_id;
	ELSE
		vr_id := gen_random_uuid();
	
		INSERT INTO wf_state_connections (
			application_id,
			"id",
			workflow_id,
			in_state_id,
			out_state_id,
			sequence_number,
			"label",
			attachment_required,
			node_required,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_id,
			vr_workflow_id,
			vr_in_state_id,
			vr_out_state_id,
			vr_sequence_number,
			'',
			FALSE,
			FALSE,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	RETURN vr_id;
END;
$$ LANGUAGE plpgsql;

