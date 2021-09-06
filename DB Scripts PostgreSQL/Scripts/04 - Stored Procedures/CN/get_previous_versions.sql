DROP FUNCTION IF EXISTS cn_get_previous_versions;

CREATE OR REPLACE FUNCTION cn_get_previous_versions
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
	vr_check_privacy 	BOOLEAN,
	vr_now		 		TIMESTAMP,
	vr_default_privacy	VARCHAR(50)
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_node_ids			UUID[];
	vr_permission_types	string_pair_table_type[];
BEGIN
	vr_node_ids := ARRAY(
		WITH RECURSIVE hirarchy (node_id, previous_version_id, "level", "name")
		AS 
		(
			SELECT node_id, previous_version_id, 0::INTEGER AS "level", "name"
			FROM cn_nodes
			WHERE application_id = vr_application_id AND node_id = vr_node_id

			UNION ALL

			SELECT nd.node_id, nd.previous_version_id, "level" + 1, nd.name
			FROM cn_nodes AS nd
				INNER JOIN hirarchy AS hr
				ON nd.application_id = vr_application_id AND nd.node_id = hr.previous_version_id
			WHERE nd.node_id <> hr.node_id AND nd.deleted = FALSE
		)
		SELECT node_id
		FROM hirarchy
		WHERE node_id <> vr_node_id
		ORDER BY "level" ASC
	);
	
	IF vr_check_privacy = TRUE THEN
		vr_permission_types := ARRAY(
			SELECT 'View', vr_default_privacy
		);
	
		vr_node_ids := ARRAY(
			SELECT rf.id
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_node_ids, 'Node', vr_now, vr_permission_types) AS rf	
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_node_ids, NULL, NULL);
END;
$$ LANGUAGE plpgsql;

