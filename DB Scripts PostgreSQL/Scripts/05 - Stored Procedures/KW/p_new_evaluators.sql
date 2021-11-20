DROP FUNCTION IF EXISTS kw_p_new_evaluators;

CREATE OR REPLACE FUNCTION kw_p_new_evaluators
(
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_evaluator_user_ids	UUID[],
    vr_now				 	TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	/* Steps: */
	-- 1: Send new dashboards to admins
	
	-- Send new dashboards
	DROP TABLE IF EXISTS vr_dash_23952;
	
	CREATE TEMP TABLE vr_dash_23952 OF dashboard_table_type;
	
	INSERT INTO vr_dash_23952 (
		user_id, 
		node_id, 
		ref_item_id, 
		"type", 
		sub_type, 
		removable, 
		send_date
	)
	SELECT	ev,
			vr_node_id,
			vr_node_id,
			'Knowledge',
			'Evaluator',
			FALSE,
			vr_now
	FROM UNNEST(vr_evaluator_user_ids) AS ev;
	
	vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
		SELECT d
		FROM vr_dash_23952 AS d
	));
	
	RETURN QUERY
	SELECT d.*
	FROM vr_dash_23952 AS d
	WHERE vr_result > 0;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

