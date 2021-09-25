DROP FUNCTION IF EXISTS cn_p_set_node_creators;

CREATE OR REPLACE FUNCTION cn_p_set_node_creators
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_creators			guid_float_table_type[],
	vr_status			VARCHAR(20),
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	IF (SELECT COUNT(*) FROM vr_creators) = 0 THEN
		RETURN 1;
	END IF;
	
	UPDATE cn_node_creators
	SET collaboration_share = CASE WHEN rf.first_value IS NULL THEN nc.collaboration_share ELSE rf.second_value END,
		status = CASE WHEN rf.first_value IS NULL THEN nc.status ELSE vr_status END,
		deleted = CASE WHEN rf.first_value IS NULL THEN TRUE ELSE FALSE END,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM cn_node_creators AS nc
		LEFT JOIN UNNEST(vr_creators) AS rf
		ON rf.first_value = nc.user_id
	WHERE nc.application_id = vr_application_id AND nc.node_id = vr_node_id;
	
	INSERT INTO cn_node_creators (
		application_id,
		node_id,
		user_id,
		collaboration_share,
		status,
		creator_user_id,
		creation_date,
		deleted,
		unique_id
	)
	SELECT	vr_application_id, vr_node_id, rf.first_value, rf.second_value, 
			vr_status, vr_current_user_id, vr_now, FALSE, gen_random_uuid()
	FROM UNNEST(vr_creators) AS rf
		LEFT JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND 
			nc.node_id = vr_node_id AND nc.user_id = rf.first_value
	WHERE nc.node_id IS NULL;
	
	RETURN ARRAY_LENGTH(vr_creators, 1)::INTEGER;
END;
$$ LANGUAGE plpgsql;
