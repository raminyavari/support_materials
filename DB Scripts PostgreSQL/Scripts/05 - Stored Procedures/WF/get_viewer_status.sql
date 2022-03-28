DROP FUNCTION IF EXISTS wf_get_viewer_status;

CREATE OR REPLACE FUNCTION wf_get_viewer_status
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_owner_id			UUID
)
RETURNS VARCHAR
AS
$$
DECLARE
	vr_has_workflow				BOOLEAN;
	vr_is_owner 				BOOLEAN;
	vr_workflow_id 				UUID;
	vr_state_id 				UUID;
	vr_director_node_id 		UUID;
	vr_director_user_id 		UUID;
	vr_is_admin_from_workflow 	BOOLEAN;
	vr_is_node_member 			BOOLEAN;
	vr_is_admin 				BOOLEAN DEFAULT FALSE;
BEGIN
	vr_has_workflow := COALESCE((
		SELECT TRUE
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND 
			h.owner_id = vr_owner_id AND h.deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
		
	IF vr_has_workflow = FALSE THEN
		RETURN 'NotInWorkFlow';
	END IF;
	
	vr_is_owner := COALESCE(cn_p_is_node_creator(vr_application_id, vr_owner_id, vr_user_id), FALSE)::BOOLEAN;
	
	SELECT 	h.workflow_id, 
			h.state_id,
			h.director_node_id,
			h.director_user_id
	INTO	vr_workflow_id,
			vr_state_id,
			vr_director_node_id,
			vr_director_user_id
	FROM wf_history AS h
	WHERE h.application_id = vr_application_id AND 
		h.owner_id = vr_owner_id AND h.deleted = FALSE
	ORDER BY h.id DESC
	LIMIT 1;
	
	IF vr_user_id = vr_director_user_id THEN
		RETURN 'Director';
	ELSE
		vr_is_node_member := cn_p_is_node_member(vr_application_id, vr_director_node_id, 
												 vr_user_id, vr_is_admin, 'Accepted');
		
		IF vr_is_node_member = TRUE THEN
			vr_is_admin_from_workflow := COALESCE((
				SELECT s.admin 
				FROM wf_workflow_states AS s
				WHERE s.application_id = vr_application_id AND 
					s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id
				LIMIT 1
			), FALSE)::BOOLEAN;
			
			IF vr_is_admin_from_workflow = TRUE THEN
				vr_is_admin := cn_p_is_node_admin(vr_application_id, vr_director_node_id, vr_user_id);
			END IF;
		ELSE
			IF vr_is_owner = TRUE THEN
				RETURN 'Owner';
			ELSE
				RETURN 'None';
			END IF;
			
			RETURN NULL::VARCHAR;
		END IF;
		
		IF vr_is_admin_from_workflow = FALSE OR vr_is_admin = TRUE THEN
			RETURN 'Director';
		ELSE 
			RETURN 'DirectorNodeMember';
		END IF;
	END	IF;
	
	RETURN NULL::VARCHAR;
END;
$$ LANGUAGE plpgsql;

