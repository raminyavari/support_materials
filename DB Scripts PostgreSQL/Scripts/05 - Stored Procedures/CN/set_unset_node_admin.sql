DROP FUNCTION IF EXISTS cn_set_unset_node_admin;

CREATE OR REPLACE FUNCTION cn_set_unset_node_admin
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_admin		 BOOLEAN,
    vr_unique		 BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_members	guid_pair_table_type[];
	vr_result	INTEGER = 0;
BEGIN
	IF vr_admin IS NULL THEN 
		vr_admin := FALSE;
	END IF;
	
	IF vr_admin = TRUE AND vr_unique = TRUE THEN
		vr_members := ARRAY(
			SELECT ROW(nm.node_id, nm.user_id)
			FROM cn_node_members AS nm
			WHERE nm.application_id = vr_application_id AND nm.node_id = vr_node_id AND nm.is_admin = TRUE
		);
		
		vr_result := cn_p_update_members(vr_application_id, vr_members, NULL, FALSE, NULL, NULL, NULL, NULL);
		
		IF vr_result <= 0 THEN
			CALL gfn_raise_exception();
			RETURN -1;
		END IF;
	END IF;
	
	vr_result := cn_p_update_member(vr_application_id, vr_node_id, vr_user_id, NULL, vr_admin, NULL, NULL, NULL, NULL);
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

