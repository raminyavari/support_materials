DROP FUNCTION IF EXISTS cn_set_contribution_limits;

CREATE OR REPLACE FUNCTION cn_set_contribution_limits
(
	vr_application_id		UUID,
	vr_node_type_id			UUID,
	vr_limit_node_type_ids	guid_table_type[],
	vr_current_user_id		UUID,
	vr_now					TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	UPDATE cn_contribution_limits
	SET deleted = CASE WHEN x.value IS NULL THEN TRUE ELSE FALSE END::BOOLEAN,
		last_modifier_user_id = CASE WHEN x.value IS NULL THEN cl.last_modifier_user_id ELSE vr_current_user_id END,
		last_modification_date = CASE WHEN x.value IS NULL THEN cl.last_modification_date ELSE vr_now END
	FROM cn_contribution_limits AS cl
		LEFT JOIN UNNEST(vr_limit_node_type_ids) AS x
		ON x.value = cl.limit_node_type_id
	WHERE cl.application_id = vr_application_id AND cl.node_type_id = vr_node_type_id;
	
	INSERT INTO cn_contribution_limits (
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
		LEFT JOIN cn_contribution_limits AS cl
		ON cl.application_id = vr_application_id AND 
			cl.node_type_id = vr_node_type_id AND cl.limit_node_type_id = x.value
	WHERE cl.node_type_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;
