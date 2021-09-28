DROP FUNCTION IF EXISTS cn_set_service_admin_type;

CREATE OR REPLACE FUNCTION cn_set_service_admin_type
(
	vr_application_id		UUID,
	vr_node_type_id			UUID,
	vr_admin_type			VARCHAR(20),
	vr_admin_node_id		UUID,
	vr_limit_node_type_ids	guid_table_type[],
	vr_current_user_id		UUID,
	vr_now					TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result			INTEGER;
BEGIN
	UPDATE cn_services AS s
	SET admin_type = vr_admin_type,
		admin_node_id = COALESCE(vr_admin_node_id, s.admin_node_id)
	WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	UPDATE cn_admin_type_limits
	SET deleted = CASE WHEN x.value IS NULL THEN TRUE ELSE FALSE END::BOOLEAN,
		last_modifier_user_id = CASE WHEN x.value IS NULL THEN atl.last_modifier_user_id ELSE vr_current_user_id END,
		last_modification_date = CASE WHEN x.value IS NULL THEN atl.last_modification_date ELSE vr_now END
	FROM cn_admin_type_limits AS atl
		LEFT JOIN UNNEST(vr_limit_node_type_ids) AS x
		ON x.value = atl.limit_node_type_id
	WHERE atl.application_id = vr_application_id AND atl.node_type_id = vr_node_type_id;
	
	INSERT INTO cn_admin_type_limits (
		application_id,
		node_type_id,
		limit_node_type_id,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT 	vr_application_id, 
			vr_node_type_id, 
			x.value, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_limit_node_type_ids) AS x
		LEFT JOIN cn_admin_type_limits AS atl
		ON atl.application_id = vr_application_id AND 
			atl.node_type_id = vr_node_type_id AND atl.limit_node_type_id = x.value
	WHERE atl.node_type_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;
