DROP FUNCTION IF EXISTS cn_p_get_node_hierarchy;

CREATE OR REPLACE FUNCTION cn_p_get_node_hierarchy
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_same_type 		BOOLEAN
)
RETURNS TABLE (
	"id"		UUID, 
	parent_id	UUID, 
	"level"		VARCHAR, 
	"name"		VARCHAR
)
AS
$$
DECLARE
	vr_node_type_id	UUID;
BEGIN
	IF vr_same_type = TRUE THEN
		vr_node_type_id := ARRAY(
			SELECT nd.node_type_id 
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
			LIMIT 1
		);
	END IF;
	
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", parent_id, "level", "name")
 	AS 
	(
		SELECT nd.node_id AS "id", nd.parent_node_id AS parent_id, 0::INTEGER AS "level", nd.name
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		
		UNION ALL
		
		SELECT node.node_id AS id, node.parent_node_id AS parent_id, hr.level + 1, node.name
		FROM cn_nodes AS node
			INNER JOIN "hierarchy" AS hr
			ON hr.parent_id = node.node_id
		WHERE node.application_id = vr_application_id AND 
			(vr_node_type_id IS NULL OR node.node_type_id = vr_node_type_id) AND
			node.node_id <> hr.id AND node.deleted = FALSE
	)
	SELECT * 
	FROM "hierarchy"
	ORDER BY "hierarchy".level ASC;
END;
$$ LANGUAGE plpgsql;

