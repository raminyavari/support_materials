DROP FUNCTION IF EXISTS wf_remove_workflow_state_tag;

CREATE OR REPLACE FUNCTION wf_remove_workflow_state_tag
(
	vr_application_id	UUID,
    vr_workflow_id		UUID,
	vr_state_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER DEFAULT 0;
BEGIN
	UPDATE wf_workflow_states AS s
	SET tag_id = NULL
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

