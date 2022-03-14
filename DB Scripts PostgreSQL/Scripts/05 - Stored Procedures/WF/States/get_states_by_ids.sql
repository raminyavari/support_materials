DROP FUNCTION IF EXISTS wf_get_states_by_ids;

CREATE OR REPLACE FUNCTION wf_get_states_by_ids
(
	vr_application_id	UUID,
	vr_state_ids		guid_table_type[]
)
RETURNS SETOF wf_state_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_state_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM wf_p_get_states_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

