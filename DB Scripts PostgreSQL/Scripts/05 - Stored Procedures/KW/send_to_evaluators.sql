DROP FUNCTION IF EXISTS kw_send_to_evaluators;

CREATE OR REPLACE FUNCTION kw_send_to_evaluators
(
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_current_user_id		UUID,
    vr_evaluator_user_ids	guid_table_type[],
    vr_description	 		VARCHAR(2000),
    vr_now			 		TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_searchable_after		VARCHAR(50);
	vr_searchability_status BOOLEAN;
	vr_searchable 			BOOLEAN;
	vr_previous_version_id 	UUID;
	vr_result				INTEGER;
BEGIN
	/* Steps: */
	-- 1: Set knowledge status to 'SentToEvaluators'
	-- 2: Create History
	-- 3: Set current user's admin dashboard AS done
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	
	SELECT vr_searchable_after = kt.searchable_after
	FROM cn_nodes AS nd
		INNER JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = nd.node_type_id
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	
	-- Set new knowledge status
	vr_searchability_status := COALESCE((
		SELECT nd.searchable
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		LIMIT 1
	), TRUE)::BOOLEAN;
	
	vr_searchable := CASE WHEN vr_searchable_after = 'Confirmation' THEN TRUE ELSE vr_searchability_status END::BOOLEAN;
	
	UPDATE cn_nodes AS nd
	SET status = 'SentToEvaluators',
		searchable = CASE WHEN vr_searchable_after = 'Confirmation' THEN TRUE ELSE nd.searchable END
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of set new knowledge status
	
	
	-- Set searchability of previous version
	IF vr_searchability_status = FALSE AND vr_searchable = TRUE THEN
		SELECT vr_previous_version_id = nd.previous_version_id
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		LIMIT 1;
		
		IF vr_previous_version_id IS NOT NULL THEN
			UPDATE cn_nodes AS nd
			SET searchable = FALSE
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_previous_version_id;
		END IF;
	END IF;
	-- end of Set searchability of previous version
	
	
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		description,
		actor_user_id,
		action_date,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'SendToEvaluators',
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	);
	-- end of create history
	
	
	-- Set dashboards AS done
	vr_result := ntfn_p_set_dashboards_as_done(vr_application_id, vr_current_user_id, 
											   vr_node_id, NULL, 'Knowledge', 'Admin', vr_now);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of set dashboards AS done
	
	
	-- Remove all existing dashboards
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, 
													 vr_node_id, NULL, NULL, NULL);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of remove all existing dashboards
	
	
	-- Send new dashboards
	DROP TABLE IF EXISTS vr_dash_09852;
	
	CREATE TEMP TABLE vr_dash_09852 OF dashboard_table_type;
	
	INSERT INTO vr_dash_09852
	SELECT x.*
	FROM kw_p_new_evaluators(vr_application_id, vr_node_id, ARRAY(
		SELECT rv.value
		FROM UNNEST(vr_evaluator_user_ids) AS rf
	), vr_now) AS x;
	
	IF (SELECT COUNT(*) FROM vr_dash_09852) = 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	ELSE
		RETURN QUERY
		SELECT x.*
		FROM vr_dash_09852 AS x;
	END IF;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

