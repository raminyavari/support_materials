DROP FUNCTION IF EXISTS kw_send_back_for_revision;

CREATE OR REPLACE FUNCTION kw_send_back_for_revision
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
    vr_text_options	 	VARCHAR(1000),
    vr_description	 	VARCHAR(2000),
    vr_now			 	TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	/* Steps: */
	-- 1: Set knowledge status to 'SentBackForRevision'
	-- 2: Create history
	-- 3: Set current user's admin dashboard AS done
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	-- Set new knowledge status
	UPDATE cn_nodes AS nd
	SET status = 'SentBackForRevision'
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	-- end of set new knowledge status
	
	
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		text_options,
		description,
		actor_user_id,
		action_date,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'SendBackForRevision',
		vr_text_options,
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
	DROP TABLE IF EXISTS vr_dash_39852;
	
	CREATE TEMP TABLE vr_dash_39852 OF dashboard_table_type;
	
	INSERT INTO vr_dash_39852 (
		user_id, 
		node_id, 
		ref_item_id, 
		"type", 
		sub_type, 
		removable, 
		send_date
	)
	SELECT	nd.creator_user_id,
			vr_node_id,
			vr_node_id,
			'Knowledge',
			'Revision',
			TRUE,
			vr_now
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
		SELECT d
		FROM vr_dash_39852 AS d
	));
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
	ELSE
		RETURN QUERY
		SELECT d.*
		FROM vr_dash_39852 AS d;
	END IF;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

