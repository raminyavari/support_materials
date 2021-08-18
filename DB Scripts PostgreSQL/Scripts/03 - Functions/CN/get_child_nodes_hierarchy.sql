DROP FUNCTION IF EXISTS cn_fn_get_child_nodes_hierarchy;

CREATE OR REPLACE FUNCTION cn_fn_get_child_nodes_hierarchy
(
	vr_application_id	UUID,
	vr_node_ids			UUID[]
)
RETURNS TABLE (
	node_id 	UUID,
	parent_id 	UUID,
	"level" 	INTEGER,
	"name" 		VARCHAR(2000)
)
AS
$$
BEGIN
	CREATE TEMP TABLE tbl (
		"id" 		UUID,
		parent_id 	UUID,
		"level" 	INTEGER,
		"name" 		VARCHAR(2000)
	);

	INSERT INTO tbl("id", parent_id, "level", "name")
	SELECT nd.node_id AS "id", nd.parent_node_id AS parent_id, 0 AS "level", nd.name
	FROM UNNEST(vr_node_ids) AS n
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = n;
	
	INSERT INTO tbl("id", parent_id, "level", "name")
	SELECT nd.node_id AS "id", nd.parent_node_id AS parent_id, "level" + 1, nd.name
	FROM tbl
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.parent_node_id = tbl.id
	WHERE nd.node_id <> tbl.id AND nd.deleted = FALSE;
	
	RETURN QUERY
	SELECT *
	FROM tbl;
END;
$$ LANGUAGE PLPGSQL;