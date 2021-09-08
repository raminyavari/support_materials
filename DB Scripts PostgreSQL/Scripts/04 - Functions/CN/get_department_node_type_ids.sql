DROP FUNCTION IF EXISTS cn_fn_get_department_node_type_ids;

CREATE OR REPLACE FUNCTION cn_fn_get_department_node_type_ids
(
	vr_application_id	UUID
)
RETURNS TABLE (
	node_type_id	UUID,
	parent_id 		UUID,
	"level"			INTEGER,
	"name" 			VARCHAR(2000)
)
AS
$$
BEGIN
	RETURN QUERY
	WITH RECURSIVE "hierarchy" ("id", "parent_id", "level", "name")
 	AS 
	(
		SELECT nt.node_type_id AS "id", nt.parent_id, 0::INTEGER AS "level", nt.name
		FROM cn_node_types AS nt
		WHERE nt.application_id = vr_application_id AND nt.additional_id = '6'
		
		UNION ALL
		
		SELECT nt.node_type_id AS "id", nt.parent_id, hr."level" + 1 AS "level", nt.name
		FROM cn_node_types AS nt
			INNER JOIN "hierarchy" AS hr
			ON nt.parent_id = hr.id
		WHERE nt.node_type_id <> hr.id AND nt.deleted = FALSE
	)
	SELECT h.id, h.parent_id, h.level, h.name
	FROM "hierarchy" AS h;
END;
$$ LANGUAGE PLPGSQL;