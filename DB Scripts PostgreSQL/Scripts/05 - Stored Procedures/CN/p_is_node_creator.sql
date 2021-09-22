DROP FUNCTION IF EXISTS cn_p_is_node_creator;

CREATE OR REPLACE FUNCTION cn_p_is_node_creator
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		WHERE EXISTS(
				SELECT * 
				FROM cn_nodes AS nd
				WHERE nd.application_id = vr_application_id AND 
					nd.node_id = vr_node_id AND nd.creator_user_id = vr_user_id
				LIMIT 1
			) OR EXISTS(
				SELECT * 
				FROM cn_node_creators AS nc
				WHERE nc.application_id = vr_application_id AND 
					nc.node_id = vr_node_id AND nc._user_id = vr_user_id AND deleted = FALSE
				LIMIT 1
			)
	), 0)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

