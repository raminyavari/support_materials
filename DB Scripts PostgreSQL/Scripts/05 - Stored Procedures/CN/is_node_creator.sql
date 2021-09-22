DROP FUNCTION IF EXISTS cn_is_node_creator;

CREATE OR REPLACE FUNCTION cn_is_node_creator
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_node_type_id		UUID,
    vr_additional_id	VARCHAR(50),
    vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	IF vr_node_id IS NULL AND vr_additional_id IS NOT NULL THEN
		WITH x (node_id)
	 	AS 
		(
			SELECT nd.node_id 
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND 
				(vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
				nd.additional_id = vr_additional_id
		)
		SELECT vr_node_id = x.node_id
		FROM x
		WHERE (SELECT COUNT(*) FROM x) = 1
		LIMIT 1;
	END IF;
	
    RETURN cn_p_is_node_creator(vr_application_id, vr_node_id, vr_user_id);
END;
$$ LANGUAGE plpgsql;

