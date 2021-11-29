DROP FUNCTION IF EXISTS wk_p_send_dashboards;

CREATE OR REPLACE FUNCTION wk_p_send_dashboards
(
	vr_application_id	UUID,
	vr_ref_item_id		UUID,
	vr_node_id			UUID,
	vr_admin_user_ids	UUID[],
	vr_send_date	 	TIMESTAMP
)
RETURNS TABLE (
	"result"	INTEGER,
	dashboards	dashboard_table_type[]
)
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(ARRAY_LENGTH(vr_admin_user_ids, 1), 0) = 0 THEN
		RETURN QUERY
		SELECT 	1::INTEGER, 
				ARRAY[]::dashboard_table_type[];
		
		RETURN;
	END IF;
	
	DROP TABLE IF EXISTS vr_ids_34582;
	
	CREATE TEMP TABLE vr_ids_34582 (
		user_id 	UUID,
		"exists"	BOOLEAN
	);

	INSERT INTO vr_ids_34582 (user_id, "exists")
	SELECT 	"a".value, 
			MAX(CASE WHEN d.id IS NULL THEN FALSE ELSE TRUE END)
	FROM UNNEST(vr_admin_user_ids) AS "a"
		LEFT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = "a" AND 
			d.node_id = vr_node_id AND d.type = 'Wiki' AND d.deleted = FALSE AND d.done = FALSE
	GROUP BY "a";
		
	IF EXISTS (
		SELECT 1
		FROM vr_ids_34582 AS x 
		WHERE x.exists = TRUE
		LIMIT 1
	) THEN
		UPDATE ntfn_dashboards
		SET seen = FALSE
		FROM vr_ids_34582 AS u_ids
			INNER JOIN ntfn_dashboards AS d
			ON d.user_id = u_ids.user_id
		WHERE d.application_id = vr_application_id AND uids.exists = TRUE AND 
			d.node_id = vr_node_id AND d.type = 'Wiki' AND d.done = FALSE AND d.deleted = FALSE;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		IF vr_result <= 0 THEN
			RETURN QUERY
			SELECT 	vr_result, 
					ARRAY[]::dashboard_table_type[];
		
			RETURN;
		END IF;
	END IF;
	
	IF EXISTS (
		SELECT 1
		FROM vr_ids_34582 AS x 
		WHERE x.exists = FALSE
		LIMIT 1
	) THEN
		DROP TABLE IF EXISTS vr_dash_09837;
		
		CREATE TEMP TABLE vr_dash_09837 OF dashboard_table_type;
	
		INSERT INTO vr_dash_09837(
			user_id, 
			node_id, 
			ref_item_id, 
			"type", 
			removable, 
			send_date
		)
		SELECT	u_ids.user_id, 
				vr_node_id, 
				vr_ref_item_id, 
				'Wiki', 
				TRUE, 
				vr_send_date
		FROM vr_dash_09837 AS u_ids
		WHERE u_ids.exists = FALSE;
		
		vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
			SELECT x
			FROM vr_dash_09837 AS x
		));
		
		IF vr_result <= 0 THEN
			RETURN QUERY
			SELECT 	vr_result, 
					ARRAY[]::dashboard_table_type[];
		
			RETURN;
		ELSE
			RETURN QUERY
			SELECT 	vr_result, 
					ARRAY(
						SELECT *
						FROM vr_dash_09837
					);
		
			RETURN;
		END IF;
	END IF;
	
	RETURN QUERY
	SELECT 	1::INTEGER, 
			ARRAY[]::dashboard_table_type[];
END;
$$ LANGUAGE plpgsql;

