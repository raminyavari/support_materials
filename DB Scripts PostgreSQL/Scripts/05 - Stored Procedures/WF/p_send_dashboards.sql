DROP FUNCTION IF EXISTS wf_p_send_dashboards;

CREATE OR REPLACE FUNCTION wf_p_send_dashboards
(
	vr_application_id			UUID,
	vr_history_id				UUID,
	vr_node_id					UUID,
	vr_workflow_id				UUID,
	vr_state_id					UUID,
	vr_director_user_id			UUID,
	vr_director_node_id			UUID,
	vr_data_need_instance_id	UUID,
	vr_send_date		 		TIMESTAMP,
	OUT "result"				INTEGER,
	OUT dashboards				REFCURSOR
)
AS
$$
DECLARE
	vr_only_send_data_need		BOOLEAN DEFAULT FALSE;
	vr_workflow_name 			VARCHAR(1000);
	vr_state_title 				VARCHAR(1000);
	vr_info 					VARCHAR;
	vr_is_director_node_admin 	BOOLEAN;
	vr_dash_result				REFCURSOR;
BEGIN
	IF vr_data_need_instance_id IS NOT NULL THEN
		vr_only_send_data_need := TRUE;
		
		IF vr_history_id IS NULL THEN
			vr_history_id := (
				SELECT s.history_id
				FROM wf_state_data_need_instances AS s
				WHERE s.application_id = vr_application_id AND s.instance_id = vr_data_need_instance_id
				LIMIT 1
			);
		END IF;
		
		IF vr_workflow_id IS NULL OR vr_state_id IS NULL OR vr_node_id IS NULL THEN
			SELECT INTO vr_workflow_id, vr_state_id, vr_node_id
						h.workflow_id, h.state_id, h.owner_id
			FROM wf_history AS h
			WHERE h.application_id = vr_application_id AND h.history_id = vr_history_id;
		END IF;
	END IF;
	
	DROP TABLE IF EXISTS dashboards_52385;
	
	CREATE TEMP TABLE dashboards_52385 OF dashboard_table_type;
	
	SELECT INTO vr_workflow_name
				w.name 
	FROM wf_workflows AS w
	WHERE w.application_id = vr_application_id AND w.workflow_id = vr_workflow_id
	LIMIT 1;
	
	SELECT INTO vr_state_title
				s.title 
	FROM wf_states AS s
	WHERE s.application_id = vr_application_id AND s.state_id = vr_state_id
	LIMIT 1;
	
	INSERT INTO dashboards_52385 (
		user_id, 
		node_id, 
		ref_item_id, 
		"type", 
		"info", 
		removable, 
		send_date
	)
	SELECT	nm.user_id, 
			vr_node_id, 
			sdni.instance_id, 
			'WorkFlow',
			wf_fn_get_dashboard_info(vr_workflow_name, vr_state_title, sdni.instance_id),
			FALSE,
			vr_send_date
	FROM wf_state_data_need_instances AS sdni
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = sdni.node_id AND nm.is_pending = FALSE
	WHERE sdni.application_id = vr_application_id AND (
			(vr_only_send_data_need = TRUE AND sdni.instance_id = vr_data_need_instance_id) OR
			(vr_only_send_data_need = FALSE AND sdni.history_id = vr_history_id)
		) AND
		(sdni.admin = FALSE OR sdni.admin = nm.is_admin) AND sdni.deleted = FALSE;
	
	IF vr_only_send_data_need = FALSE THEN
		vr_info := wf_fn_get_dashboard_info(vr_workflow_name, vr_state_title, vr_data_need_instance_id);
	
		IF vr_director_user_id IS NOT NULL THEN
			INSERT INTO dashboards_52385 (
				user_id, 
				node_id, 
				ref_item_id, 
				"type", 
				"info", 
				removable, 
				send_date
			)
			VALUES (
				vr_director_user_id, 
				vr_node_id, 
				vr_history_id, 
				'WorkFlow', 
				vr_info, 
				FALSE, 
				vr_send_date
			);
		END IF;
	
		IF vr_director_node_id IS NOT NULL THEN
			SELECT INTO vr_is_director_node_admin
						s.admin
			FROM wf_workflow_states AS s
			WHERE s.application_id = vr_application_id AND s.workflow_id = vr_workflow_id AND 
				s.state_id = vr_state_id AND deleted = FALSE
			LIMIT 1;
		
			INSERT INTO dashboards_52385 (
				user_id, 
				node_id, 
				ref_item_id, 
				"type", 
				"info", 
				removable, 
				send_date
			)
			SELECT	nm.user_id, 
					vr_node_id, 
					vr_history_id, 
					'WorkFlow', 
					vr_info, 
					CASE
						WHEN COALESCE(vr_is_director_node_admin, FALSE) = FALSE OR nm.is_admin = TRUE THEN FALSE
						ELSE TRUE
					END::BOOLEAN,
					vr_send_date
			FROM cn_view_node_members AS nm
			WHERE nm.application_id = vr_application_id AND nm.node_id = vr_director_node_id AND 
				nm.is_pending = FALSE AND NOT EXISTS (
					SELECT 1
					FROM dashboards_52385 AS rf 
					WHERE rf.user_id = nm.user_id
					LIMIT 1
				);
		END IF;
		
		SELECT 	ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, vr_node_id, NULL, 'WorkFlow', NULL)
		INTO 	"result";
		
		IF "result" <= 0 THEN
			RETURN;
		END IF;
	END IF; -- end of 'IF vr_only_send_data_need = 1 BEGIN'
	
	IF (SELECT COUNT(*) FROM dashboards_52385) = 0 THEN
		SELECT 	-1::INTEGER
		INTO	"result";
		
		RETURN;
	END IF;
	
	SELECT 	ntfn_p_send_dashboards(
				vr_application_id, 
				ARRAY(
					SELECT x 
					FROM dashboards_52385 AS x
				))
	INTO	"result";
	
	IF "result" > 0 THEN
		OPEN vr_dash_result FOR
		SELECT * 
		FROM dashboards_52385;
		
		SELECT 	vr_dash_result
		INTO 	dashboards;
	END IF;
END;
$$ LANGUAGE plpgsql;

