DROP FUNCTION IF EXISTS ntfn_set_dashboards_as_seen;

CREATE OR REPLACE FUNCTION ntfn_set_dashboards_as_seen
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_dashboard_ids	big_int_table_type[],
    vr_now			 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE ntfn_dashboards
	SET seen = TRUE,
		view_date = vr_now
	FROM UNNEST(vr_dashboard_ids) AS rf
		INNER JOIN ntfn_dashboards AS d
		ON d.id = rf.value
	WHERE d.application_id = vr_application_id AND d.user_id = vr_user_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

