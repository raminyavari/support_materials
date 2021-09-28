DROP FUNCTION IF EXISTS cn_p_initialize_service;

CREATE OR REPLACE FUNCTION cn_p_initialize_service
(
	vr_application_id	UUID,
	vr_node_type_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_seq_no	INTEGER;
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM cn_services AS s
		WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id
		LIMIT 1
	) THEN
		UPDATE cn_services AS s
		SET deleted = FALSE
		WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id;
	ELSE
		vr_seq_no := COALESCE((
			SELECT MAX(s.sequence_number) 
			FROM cn_services AS s
			WHERE s.application_id = vr_application_id
		), 0)::INTEGER + 1;
		
		INSERT INTO cn_services(
			application_id,
			node_type_id,
			enable_contribution,
			editable_for_admin,
			sequence_number,
			editable_for_creator,
			editable_for_owners,
			editable_for_experts,
			editable_for_members,
			edit_suggestion,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_node_type_id,
			FALSE,
			TRUE,
			vr_seq_no,
			TRUE,
			TRUE,
			TRUE,
			FALSE,
			TRUE,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
