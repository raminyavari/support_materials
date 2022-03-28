DROP FUNCTION IF EXISTS wf_send_to_next_state;

CREATE OR REPLACE FUNCTION wf_send_to_next_state
(
	vr_application_id	UUID,
	vr_prev_history_id	UUID,
    vr_state_id			UUID,
    vr_director_node_id	UUID,
    vr_director_user_id	UUID,
    vr_description	 	VARCHAR(2000),
    vr_reject			BOOLEAN,
    vr_sender_user_id	UUID,
    vr_send_date		TIMESTAMP,
	vr_attached_files	doc_file_info_table_type[]
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_history_id				UUID;
	vr_owner_id 				UUID;
	vr_workflow_id 				UUID;
	vr_prev_state_id			UUID;
	vr_max_allowed_rejections 	INTEGER;
	vr_rejection_ref_state_id 	UUID;
	vr_data_needs_type 			VARCHAR(20);
	vr_ref_data_needs_state_id 	UUID;
	vr_form_id 					UUID;
	vr_state_title 				VARCHAR(1000);
	vr_hide_contributors 		BOOLEAN;
	vr_result					INTEGER;
	vr_cur_result				REFCURSOR;
	vr_cur_dash					REFCURSOR;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	vr_reject := COALESCE(vr_reject, FALSE)::BOOLEAN;
	
	SELECT 	gen_random_uuid(), 
			h.owner_id, 
			h.workflow_id,
			h.state_id
	INTO 	vr_history_id,
			vr_owner_id,
			vr_workflow_id,
			vr_prev_state_id
	FROM wf_history AS h
	WHERE h.application_id = vr_application_id AND h.history_id = vr_prev_history_id;
	
	IF vr_reject = FALSE THEN
		IF vr_director_node_id IS NULL AND vr_director_user_id IS NULL THEN
			EXECUTE gfn_raise_exception(-5::INTEGER, 'NoDirectorIsSet');
			RETURN;
		END IF;
	ELSE
		SELECT 	s.max_allowed_rejections, 
			   	s.rejection_ref_state_id
		INTO	vr_max_allowed_rejections,
				vr_rejection_ref_state_id
		FROM wf_workflow_states AS s
		WHERE s.application_id = vr_application_id AND 
			s.workflow_id = vr_workflow_id AND s.state_id = vr_prev_state_id;
		
		IF vr_max_allowed_rejections IS NULL OR vr_max_allowed_rejections <= 0 THEN
			EXECUTE gfn_raise_exception(-11::INTEGER, 'RejectionIsNotAllowed');
			RETURN;
		ELSEIF (
			SELECT COUNT(*) 
			FROM wf_history AS h
			WHERE h.application_id = vr_application_id AND h.owner_id = vr_owner_id AND 
				h.workflow_id = vr_workflow_id AND h.state_id = vr_prev_history_id AND 
				h.rejected = TRUE AND h.deleted = FALSE
		) >= vr_max_allowed_rejections THEN
			EXECUTE gfn_raise_exception(-12::INTEGER, 'MaxAllowedRejectionsExceeded');
			RETURN;
		END IF;
		
		SELECT 	h.director_node_id,
				h.director_user_id,
				h.state_id
		INTO	vr_director_node_id,
				vr_director_user_id,
				vr_state_id
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND 
			h.owner_id = vr_owner_id AND h.workflow_id = vr_workflow_id AND 
			(vr_rejection_ref_state_id IS NULL OR h.state_id = vr_rejection_ref_state_id) AND
			h.history_id <> vr_prev_history_id AND h.deleted = FALSE
		ORDER BY h.id DESC
		LIMIT 1;
	END IF;
	
	UPDATE wf_history AS h
	SET rejected = vr_reject,
		selected_out_state_id = vr_state_id,
		description = vr_description,
		actor_user_id = vr_sender_user_id
	WHERE h.application_id = vr_application_id AND h.history_id = vr_prev_history_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-6::INTEGER, 'HistoryUpdateFailed');
		RETURN;
	END IF;
	
	INSERT INTO wf_history (
		application_id,
		history_id,
		previous_history_id,
		owner_id,
		workflow_id,
		state_id,
		director_node_id,
		director_user_id,
		rejected,
		terminated,
		sender_user_id,
		send_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_history_id,
		vr_prev_history_id,
		vr_owner_id, 
		vr_workflow_id, 
		vr_state_id, 
		vr_director_node_id, 
		vr_director_user_id, 
		FALSE,
		FALSE,
		vr_sender_user_id, 
		vr_send_date, 
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-7::INTEGER, 'HistoryUpdateFailed');
		RETURN;
	END IF;
	
	SELECT 	wfs.data_needs_type, 
		   	wfs.ref_data_needs_state_id,
		   	fo.form_id
	INTO	vr_data_needs_type,
			vr_ref_data_needs_state_id,
			vr_form_id
	FROM wf_workflow_states AS wfs
		LEFT JOIN fg_form_owners AS fo
		ON fo.application_id = vr_application_id AND fo.owner_id = wfs.id
	WHERE wfs.application_id = vr_application_id AND 
		wfs.workflow_id = vr_workflow_id AND wfs.state_id = vr_state_id;
	
	IF vr_data_needs_type = 'RefState' THEN
		IF EXISTS(
			SELECT 1
			FROM wf_state_data_need_instances AS d
			WHERE d.application_id = vr_application_id AND 
				d.history_id = vr_prev_history_id AND d.deleted = FALSE
			LIMIT 1
		) THEN
			INSERT INTO wf_state_data_need_instances (
				application_id,
				instance_id,
				history_id,
				node_id,
				"admin",
				filled,
				creator_user_id,
				creation_date,
				deleted
			)
			SELECT 	vr_application_id, 
					gen_random_uuid(), 
					vr_history_id, 
					d.node_id, 
					d.admin, 
					FALSE,
					vr_sender_user_id, 
					vr_send_date, 
					FALSE
			FROM wf_state_data_need_instances AS d
			WHERE d.application_id = vr_application_id AND 
				d.history_id = vr_prev_history_id AND d.deleted = FALSE;
			
			GET DIAGNOSTICS vr_result := ROW_COUNT;
			
			IF vr_result <= 0 THEN
				EXECUTE gfn_raise_exception(-8::INTEGER, 'HistoryDateNeedsCreationFailed');
				RETURN;
			END IF;
		END IF;
		
		vr_result := fg_p_copy_form_instances(vr_application_id, vr_prev_history_id, vr_history_id, 
											  vr_form_id, vr_sender_user_id, vr_send_date);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-9::INTEGER, 'HistoryFormInstancesCopyFailed');
			RETURN;
		END IF;
	END IF;
	
	IF COALESCE(ARRAY_LENGTH(vr_attached_files, 1), 0) > 0 THEN
		vr_result := dct_p_add_files(vr_application_id, vr_prev_history_id, 'WorkFlow', 
									 vr_attached_files, vr_sender_user_id, vr_send_date);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-10::INTEGER, 'FileAttachmentFailed');
			RETURN;
		END IF;
	END IF;
	
	-- Update WFState in CN_Nodes Table
	SELECT 	s.title
	INTO	vr_state_title
	FROM wf_states AS s
	WHERE s.application_id = vr_application_id AND s.state_id = vr_state_id
	LIMIT 1;
	
	SELECT 	COALESCE(s.hide_owner_name, FALSE)::BOOLEAN
	INTO	vr_hide_contributors
	FROM wf_workflow_states AS s
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id
	LIMIT 1;
	
	vr_result := cn_p_modify_node_wf_state(vr_application_id, vr_owner_id, vr_state_title, 
										   vr_hide_contributors, vr_sender_user_id, vr_send_date);
		
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-11::INTEGER, 'StatusUpdateFailed');
		RETURN;
	END IF;
	-- end of Update WFState in CN_Nodes Table
	
	-- Send Dashboards
	vr_result := ntfn_p_set_dashboards_as_done(vr_application_id, vr_sender_user_id, vr_owner_id, 
											   vr_prev_history_id, 'WorkFlow', NULL, vr_send_date);
											   
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'UpdatingDashboardsFailed');
		RETURN;
	END IF;
	
	SELECT	x.result,
			x.dashboards
	INTO	vr_result,
			vr_cur_dash
	FROM wf_p_send_dashboards(vr_application_id, vr_history_id, vr_owner_id, vr_workflow_id, vr_state_id, 
							  vr_director_user_id, vr_director_node_id, NULL, vr_send_date) AS x;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'CannotDetermineDirector');
		RETURN;
	END IF;
	-- end of Send Dashboards
	
	OPEN vr_cur_result FOR
	SELECT 1::INTEGER;
	
	RETURN NEXT vr_cur_dash;
	RETURN NEXT vr_cur_result;
END;
$$ LANGUAGE plpgsql;

