DROP PROCEDURE IF EXISTS _cn_notify_node_expiration;

CREATE OR REPLACE PROCEDURE _cn_notify_node_expiration
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_now		 		TIMESTAMP,
	INOUT vr_dashboards	dashboard_table_type[]
)
AS
$$
DECLARE
	vr_result		INTEGER = 0;
BEGIN
	-- Send new dashboards
    IF vr_user_id IS NOT NULL THEN
		DROP TABLE IF EXISTS dashboards_40528;
	
		CREATE TEMP TABLE dashboards_40528 OF dashboard_table_type;
	
		INSERT INTO dashboards_40528(user_id, node_id, ref_item_id, "type", subtype, removable, send_date)
		VALUES (vr_user_id, vr_node_id, vr_node_id, 'Knowledge', 'ExpirationDate', FALSE, vr_now);
		
		vr_dashboards := ARRAY(
			SELECT x
			FROM dashboards_40528 AS x
		);
		
		vr_result := ntfn_p_send_dashboards(vr_application_id, vr_dashboards);
		
		IF vr_result <= 0 THEN
			CALL gfn_raise_exception(-1, NULL);
		END IF;
	END IF;
	-- end of send new dashboards
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_notify_node_expiration;

CREATE OR REPLACE FUNCTION cn_notify_node_expiration
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_now		 		TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_dashboards	dashboard_table_type[];
BEGIN
	CALL _cn_notify_node_expiration(vr_application_id, vr_node_id, vr_user_id, vr_now, vr_dashboards);
	
	RETURN QUERY
	SELECT x.*
	FROM UNNEST(vr_dashboards) AS x;
END;
$$ LANGUAGE plpgsql;

