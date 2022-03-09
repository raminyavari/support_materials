DROP FUNCTION IF EXISTS ntfn_arithmetic_delete_dashboards;

CREATE OR REPLACE FUNCTION ntfn_arithmetic_delete_dashboards
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_dashboard_ids	big_int_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE ntfn_dashboards
	SET deleted = TRUE
	FROM UNNEST(vr_dashboard_ids) AS rf
		INNER JOIN ntfn_dashboards AS d
		ON d.id = rf.value
	WHERE d.application_id = vr_application_id AND d.user_id = vr_user_id;
			
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

