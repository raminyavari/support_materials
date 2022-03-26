DROP FUNCTION IF EXISTS wf_get_workflow_auto_messages;

CREATE OR REPLACE FUNCTION wf_get_workflow_auto_messages
(
	vr_application_id	UUID,
	vr_workflow_id		UUID
)
RETURNS SETOF wf_auto_message_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM wf_p_get_owner_auto_messages(
		vr_application_id, 
		ARRAY(
			SELECT sc.id
			FROM wf_state_connections AS sc
			WHERE sc.application_id = vr_application_id AND 
				sc.workflow_id = vr_workflow_id AND sc.deleted = FALSE
		)
	);
END;
$$ LANGUAGE plpgsql;

