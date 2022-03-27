DROP FUNCTION IF EXISTS wf_get_last_history;

CREATE OR REPLACE FUNCTION wf_get_last_history
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_state_id			UUID,
	vr_done		 		BOOLEAN
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
				h.owner_id = vr_owner_id AND deleted = FALSE AND
				(vr_state_id IS NULL OR h.state_id = vr_state_id) AND
				(COALESCE(vr_done, FALSE) = FALSE OR h.actor_user_id IS NOT NULL)
			ORDER BY h.id DESC
			LIMIT 1
		)
	);
END;
$$ LANGUAGE plpgsql;

