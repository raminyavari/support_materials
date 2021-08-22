DROP FUNCTION IF EXISTS cn_fn_get_node_file_contents;

CREATE OR REPLACE FUNCTION cn_fn_get_node_file_contents
(
	vr_application_id	UUID,
	vr_node_id			UUID
)
RETURNS VARCHAR
AS
$$
DECLARE
	vr_ret	VARCHAR;
BEGIN
	WITH RECURSIVE partitioned AS (
		SELECT	oid.owner_id,
				CAST(SUBSTRING(COALESCE(fc.content, N''), 1, 4000) AS VARCHAR(4000)) AS "content",
				ROW_NUMBER() OVER (PARTITION BY oid.owner_id ORDER BY fc.file_id ASC, oid.id ASC) AS "number",
				COUNT(*) OVER (PARTITION BY oid.owner_id) AS "count"
		FROM (
				SELECT vr_node_id AS owner_id, e.element_id AS "id"
				FROM fg_form_instances AS i
					INNER JOIN fg_instance_elements AS e
					ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND 
						e.type = 'File' AND e.deleted = FALSE
				WHERE i.application_id = vr_application_id AND 
					i.owner_id = vr_node_id AND i.deleted = FALSE

				UNION

				SELECT vr_node_id AS owner_id, vr_node_id
			) AS oid
			INNER JOIN dct_files AS f
			ON f.application_id = vr_application_id AND f.deleted = FALSE AND
				(f.owner_id = oid.owner_id OR f.owner_id = oid.id) /* AND
				(
					(oid.id = oid.owner_id AND f.owner_type = N'Node') OR
					(oid.id <> oid.owner_id AND 
						(f.owner_type = N'WikiContent' OR f.owner_type = N'FormElement')
					)
				)*/
			INNER JOIN dct_file_contents AS fc
			ON fc.application_id = vr_application_id AND 
				fc.file_id = f.file_name_guid AND fc.not_extractable = FALSE
	),
	fetched AS 
	(
		SELECT	"p".owner_id, "p".content AS full_content, "p".content, "p".number, "p".count 
		FROM partitioned AS "p"
		WHERE "p".number = 1

		UNION ALL

		SELECT	"p".owner_id, "c".full_content + ' ' + "p".content, "p".content, "p".number, "p".count
		FROM partitioned AS "p"
			INNER JOIN fetched AS "c" 
			ON "p".owner_id = "c".owner_id AND "p".number = "c".number + 1
		WHERE "p".number <= 95
	)
	SELECT vr_ret = f.full_content
	FROM fetched AS f
	WHERE f.number = (CASE WHEN f.count > 90 THEN 90 ELSE f.count END)
	LIMIT 1;
	
	RETURN vr_ret;
END;
$$ LANGUAGE PLPGSQL;