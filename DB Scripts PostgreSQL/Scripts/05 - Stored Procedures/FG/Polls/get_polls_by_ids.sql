DROP FUNCTION IF EXISTS fg_get_polls_by_ids;

CREATE OR REPLACE FUNCTION fg_get_polls_by_ids
(
	vr_application_id	UUID,
	vr_poll_ids			guid_table_type[]
)
RETURNS SETOF fg_poll_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM fg_p_get_polls_by_ids(
		vr_application_id, 
		ARRAY(
			SELECT x.value 
			FROM UNNEST(vr_poll_ids) AS x
		)
	);
END;
$$ LANGUAGE plpgsql;

