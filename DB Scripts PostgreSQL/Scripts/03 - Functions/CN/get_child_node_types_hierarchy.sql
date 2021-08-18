DROP FUNCTION IF EXISTS cn_fn_get_child_node_types_hierarchy;

CREATE OR REPLACE FUNCTION cn_fn_get_child_node_types_hierarchy
(
	vr_application_id	UUID,
	vr_node_type_ids	UUID[]
)
RETURNS TABLE (
	node_type_id	UUID,
	parent_id 		UUID,
	"level" 		INTEGER,
	"name" 			VARCHAR(2000)
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
	SELECT nt.node_type_id AS "id", nt.parent_id, 0 AS "level", nt.name
	FROM UNNEST(vr_node_type_ids) AS n
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = n;
	
	INSERT INTO tbl("id", parent_id, "level", "name")
	SELECT nt.node_type_id AS "id", nt.parent_id, "level" + 1, nt.name
	FROM tbl
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.parent_id = tbl.id
	WHERE nt.node_type_id <> tbl.id AND nt.deleted = FALSE;
	
	RETURN QUERY
	SELECT *
	FROM tbl;
END;
$$ LANGUAGE PLPGSQL;