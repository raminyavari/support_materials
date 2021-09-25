DROP FUNCTION IF EXISTS cn_set_contributors;

CREATE OR REPLACE FUNCTION cn_set_contributors
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_creators			guid_float_table_type[],
	vr_owner_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_result := cn_p_set_node_creators(vr_application_id, vr_node_id, vr_contributors, 
										'Accepted', vr_current_user_id, vr_now);
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception(-1, 'ErrorInAddingNodeCreators');
		RETURN -1;
	END IF;
	
	UPDATE cn_nodes AS nd
	SET owner_id = vr_owner_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception(-1, 'SettingNodeOwnerFailed');
		RETURN -1;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
