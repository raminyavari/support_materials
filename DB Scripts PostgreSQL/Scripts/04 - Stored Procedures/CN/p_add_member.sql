DROP PROCEDURE IF EXISTS _cn_p_add_member;

CREATE OR REPLACE PROCEDURE _cn_p_add_member
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_membership_date	TIMESTAMP,
    vr_is_admin		 	BOOLEAN,
    vr_is_pending		BOOLEAN,
    vr_acception_date	TIMESTAMP,
    vr_position		 	VARCHAR(255),
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_node_type_id			UUID;
	vr_unique_membership	BOOLEAN;
	vr_unique_admin 		BOOLEAN;
	vr_members				guid_pair_table_type[];
BEGIN
	SELECT	vr_node_type_id = nd.node_type_id, 
			vr_unique_membership = COALESCE(s.unique_membership, FALSE)::BOOLEAN, 
			vr_unique_admin = COALESCE(s.unique_admin_member, FALSE)::BOOLEAN
	FROM cn_nodes AS nd
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	IF vr_unique_membership = TRUE THEN
		vr_members := ARRAY(
			SELECT nm.node_id, nm.user_id
			FROM cn_node_members AS nm
				INNER JOIN cn_nodes AS nd 
				ON nd.application_id = vr_application_id AND 
					nd.node_type_id = vr_node_type_id AND nd.node_id = nm.node_id
			WHERE nm.application_id = vr_application_id AND nm.user_id = vr_user_id AND nm.deleted = FALSE
		);
		
		vr_result := cn_p_update_members(vr_application_id, vr_members, 
										 NULL, NULL, NULL, NULL, NULL, TRUE);
		
		IF vr_result <= 0 THEN
			ROLLBACK;
			RETURN;
		END IF;
	END IF;
	
	vr_result := cn_p_update_member(vr_application_id, vr_node_id, vr_user_id, vr_membership_date, 
		vr_is_admin, vr_is_pending, vr_acception_date, vr_position, FALSE);
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_p_add_member;

CREATE OR REPLACE FUNCTION cn_p_add_member
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_membership_date	TIMESTAMP,
    vr_is_admin		 	BOOLEAN,
    vr_is_pending		BOOLEAN,
    vr_acception_date	TIMESTAMP,
    vr_position		 	VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	CALL _cn_p_add_member(vr_application_id, vr_node_id, vr_user_id, vr_membership_date, vr_is_admin,
							  vr_is_pending, vr_acception_date, vr_position, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

