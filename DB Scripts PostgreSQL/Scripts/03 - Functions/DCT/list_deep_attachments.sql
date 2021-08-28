DROP FUNCTION IF EXISTS dct_fn_list_deep_attachments;

CREATE OR REPLACE FUNCTION dct_fn_list_deep_attachments
(
	vr_application_ids	UUID[],
	vr_node_ids			UUID[],
	vr_archive	 		BOOLEAN
)
RETURNS TABLE (
	application_id	UUID,
	file_id			UUID,
	creation_date 	TIMESTAMP,
	creator_user_id	UUID,
	node_id			UUID,
	node_type_id	UUID,
	node_name		VARCHAR(500),
	node_type		VARCHAR(500),
	file_name		VARCHAR(500),
	"extension"		VARCHAR(20),
	"size"			bigint,
	owner_type		varchar(100),
	deleted		 	BOOLEAN
)
AS
$$
DECLARE
	vr_apps_count 	INTEGER;
	vr_nodes_count	INTEGER;
BEGIN
	vr_apps_count := COALESCE(ARRAY_LENGTH(vr_application_ids, 1), 0);
	vr_nodes_count := COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0);

	RETURN QUERY
	WITH Files
 	AS 
	(
		SELECT f.application_id, f.id, f.owner_id, f.owner_type, f.file_name, 
			f.extension, f.size, f.deleted, f.creator_user_id, f.creation_date
		FROM dct_files AS f
		WHERE (vr_apps_count = 0 OR f.application_id IN (SELECT UNNEST(vr_application_ids))) AND
			(vr_archive IS NULL OR f.deleted = vr_archive)
	)
	SELECT	f.application_id,
			f.id AS file_id, 
			f.creation_date,
			f.creator_user_id,
			nd.node_id, 
			nd.node_type_id,
			nd.node_name,
			nd.type_name AS node_type,
			f.file_name,
			f.extension,
			f.size,
			f.owner_type,
			(CASE WHEN nd.deleted = TRUE OR f.deleted = TRUE THEN TRUE ELSE FALSE END)::BOOLEAN AS deleted
	FROM files AS f
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = f.application_id AND nd.node_id = f.owner_id AND 
			(vr_archive IS NULL OR nd.deleted = vr_archive) AND
			(vr_nodes_count = 0 OR nd.node_id IN (SELECT UNNEST(vr_node_ids)))
	WHERE f.owner_type = 'Node' OR f.owner_type = 'WikiContent'

	UNION ALL

	SELECT	f.application_id,
			f.id AS file_id, 
			f.creation_date,
			f.creator_user_id,
			nd.node_id,
			nd.node_type_id,
			nd.node_name,
			nd.type_name AS node_type,
			f.file_name,
			f.extension,
			f.size,
			f.owner_type,
			(
				CASE 
			 		WHEN e.deleted = TRUE OR i.deleted = TRUE OR 
						nd.deleted = TRUE OR f.deleted = TRUE THEN TRUE 
					ELSE FALSE 
				END
			)::BOOLEAN AS deleted
	FROM files AS f
		INNER JOIN fg_instance_elements AS e
		ON e.application_id = f.application_id AND e.element_id = f.owner_id AND 
			e.type = 'File' AND (vr_archive IS NULL OR e.deleted = vr_archive)
		INNER JOIN fg_form_instances AS i
		ON i.application_id = f.application_id AND i.instance_id = e.instance_id AND 
			(vr_archive IS NULL OR i.deleted = vr_archive)
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = f.application_id AND nd.node_id = i.owner_id AND 
			(vr_archive IS NULL OR nd.deleted = vr_archive) AND
			(vr_nodes_count = 0 OR nd.node_id IN (SELECT UNNEST(vr_node_ids)))
	WHERE f.owner_type = 'FormElement';
END;
$$ LANGUAGE PLPGSQL;