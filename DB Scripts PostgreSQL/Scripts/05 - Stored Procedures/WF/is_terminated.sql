DROP FUNCTION IF EXISTS wf_is_terminated;

CREATE OR REPLACE FUNCTION wf_is_terminated
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT h.terminated
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND 
			h.owner_id = vr_owner_id AND h.deleted = FALSE
		ORDER BY h.id DESC
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

