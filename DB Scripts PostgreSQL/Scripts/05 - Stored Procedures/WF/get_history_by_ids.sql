DROP FUNCTION IF EXISTS wf_get_history_by_ids;

CREATE OR REPLACE FUNCTION wf_get_history_by_ids
(
	vr_application_id	UUID,
	vr_history_ids		guid_table_type[]
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
			SELECT DISTINCT h.value
			FROM UNNEST(vr_history_ids) AS h
		)
	);
END;
$$ LANGUAGE plpgsql;

