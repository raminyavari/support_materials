DROP FUNCTION IF EXISTS wf_has_workflow;

CREATE OR REPLACE FUNCTION wf_has_workflow
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND 
			h.owner_id = vr_owner_id AND h.deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

