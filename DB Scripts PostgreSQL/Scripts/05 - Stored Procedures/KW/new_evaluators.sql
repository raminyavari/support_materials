DROP FUNCTION IF EXISTS kw_new_evaluators;

CREATE OR REPLACE FUNCTION kw_new_evaluators
(
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_evaluator_user_ids	guid_table_type[],
    vr_now				 	TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_evaluator_user_ids) AS x
	);

	/* Steps: */
	-- 1: Send new dashboards to admins
	
	-- Send new dashboards
	DROP TABLE IF EXISTS vr_dash_34590;
	
	CREATE TEMP TABLE vr_dash_34590 OF dashboard_table_type;
	
	INSERT INTO vr_dash_34590
	SELECT x.*
	FROM kw_p_new_evaluators(vr_application_id, vr_node_id, vr_ids, vr_now) AS x;
	
	IF (SELECT COUNT(*) FROM vr_dash_34590) = 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	ELSE
		RETURN QUERY
		SELECT x.*
		FROM vr_dash_34590 AS x;
	END IF;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

