DROP FUNCTION IF EXISTS evt_get_events_by_ids;

CREATE OR REPLACE FUNCTION evt_get_events_by_ids
(
	vr_application_id	UUID,
    vr_event_ids 		guid_table_type[],
	vr_full		 		BOOLEAN
)
RETURNS SETOF evt_event_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_event_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM evt_p_get_events_by_ids(vr_application_id, vr_ids, vr_full);
END;
$$ LANGUAGE plpgsql;

