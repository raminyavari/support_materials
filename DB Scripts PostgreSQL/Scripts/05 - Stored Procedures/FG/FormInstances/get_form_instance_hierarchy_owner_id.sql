DROP FUNCTION IF EXISTS fg_get_form_instance_hierarchy_owner_id;

CREATE OR REPLACE FUNCTION fg_get_form_instance_hierarchy_owner_id
(
	vr_application_id	UUID,
	vr_instance_id		UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		WITH RECURSIVE "hierarchy"
		AS 
		(
			SELECT i.owner_id, 0::INTEGER AS "level"
			FROM fg_form_instances AS i
			WHERE i.application_id = vr_application_id AND i.instance_id = vr_instance_id

			UNION ALL

			SELECT i.owner_id, hr.level + 1
			FROM "hierarchy" AS hr
				INNER JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.element_id = hr.owner_id
				INNER JOIN fg_form_instances AS i
				ON i.application_id = vr_application_id AND i.instance_id = e.instance_id
			WHERE hr.owner_id IS NOT NULL AND i.owner_id <> hr.owner_id
		)
		SELECT hr.owner_id AS "id"
		FROM "hierarchy" AS hr
			INNER JOIN (
				SELECT MAX(x.level) AS "level"
				FROM "hierarchy" AS x
				LIMIT 1
			) AS "a"
			ON "a".level = hr.level
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

