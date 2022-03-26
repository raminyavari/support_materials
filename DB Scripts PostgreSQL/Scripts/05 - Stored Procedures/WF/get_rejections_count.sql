DROP FUNCTION IF EXISTS wf_get_rejections_count;

CREATE OR REPLACE FUNCTION wf_get_rejections_count
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
    vr_workflow_id		UUID,
	vr_state_id			UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN (
		SELECT COUNT(h.history_id)
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND hr.owner_id = vr_owner_id AND 
			h.workflow_id = vr_workflow_id AND h.state_id = vr_state_id AND 
			h.rejected = TRUE AND h.deleted = FALSE
	)::INTEGER;
END;
$$ LANGUAGE plpgsql;

