DROP FUNCTION IF EXISTS wf_get_history_owner_id;

CREATE OR REPLACE FUNCTION wf_get_history_owner_id
(
	vr_application_id	UUID,
	vr_history_id		UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT h.owner_id
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND h.history_id = vr_history_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

