DROP FUNCTION IF EXISTS wf_p_get_states_by_ids;

CREATE OR REPLACE FUNCTION wf_p_get_states_by_ids
(
	vr_application_id	UUID,
	vr_state_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wf_state_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT st.state_id,
		   st.title,
		   vr_total_count
	FROM UNNEST(vr_state_ids) AS x
		INNER JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = x;
END;
$$ LANGUAGE plpgsql;

