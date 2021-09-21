DROP FUNCTION IF EXISTS cn_get_node_types_hierarchy;

CREATE OR REPLACE FUNCTION cn_get_node_types_hierarchy
(
	vr_application_id	UUID,
	vr_node_type_ids 	guid_table_type[]
)
RETURNS TABLE (
	"id"		UUID, 
	parent_id	UUID, 
	"level"		VARCHAR, 
	"name"		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", parent_id, "level", "name")
 	AS 
	(
		SELECT nt.node_type_id AS "id", nt.parent_id AS parent_id, 0::INTEGER AS "level", nt.name
		FROM UNNEST(vr_node_type_ids) AS x
			INNER JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND nt.node_type_id = x.value
		
		UNION ALL
		
		SELECT nt.node_type_id AS "id", nt.parent_id AS parent_id, hr.level + 1, nt.name
		FROM cn_node_types AS nt
			INNER JOIN "hierarchy" AS hr
			ON hr.parent_id = nt.node_type_id
		WHERE nt.application_id = vr_application_id AND nt.node_type_id <> hr.id AND nt.deleted = FALSE
	)
	SELECT * 
	FROM "hierarchy"
	ORDER BY "hierarchy".level ASC;
END;
$$ LANGUAGE plpgsql;

