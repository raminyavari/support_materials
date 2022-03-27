DROP FUNCTION IF EXISTS wf_get_history;

CREATE OR REPLACE FUNCTION wf_get_history
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS SETOF wf_history_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM wf_p_get_history_by_ids(
		vr_application_id, 
		ARRAY(
			SELECT h.history_id
			FROM wf_history AS h
			WHERE h.application_id = vr_application_id AND 
				h.owner_id = vr_owner_id AND h.deleted = FALSE
		)
	);
END;
$$ LANGUAGE plpgsql;

