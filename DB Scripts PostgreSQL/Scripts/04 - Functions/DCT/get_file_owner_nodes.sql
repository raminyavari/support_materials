DROP FUNCTION IF EXISTS dct_fn_get_file_owner_nodes;

CREATE OR REPLACE FUNCTION dct_fn_get_file_owner_nodes
(
	vr_application_id	UUID,
	vr_file_ids			UUID[]
)
RETURNS TABLE (
	file_id 		UUID,
	node_id 		UUID,
	node_type_id	UUID,
	node_name 		VARCHAR(500),
	node_type 		VARCHAR(500),
	file_name 		VARCHAR(500),
	"extension" 	VARCHAR(20)
)
AS
$$
BEGIN
	RETURN QUERY
	WITH files AS
	(
		SELECT x AS "id", f.owner_id, f.owner_type, f.file_name, f.extension
		FROM UNNEST(vr_file_ids) AS x
			INNER JOIN dct_files AS f
			ON f.application_id = vr_application_id AND 
				(f.id = x OR f.file_name_guid = x) AND f.deleted = FALSE
	)
	SELECT	f.id AS file_id, 
			nd.node_id, 
			nd.node_type_id,
			nd.node_name,
			nd.type_name AS node_type,
			f.file_name,
			f.extension
	FROM files AS f
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = f.owner_id AND nd.deleted = FALSE
	WHERE f.owner_type = 'Node' OR f.owner_type = 'WikiContent'

	UNION ALL

	SELECT	f.id AS file_id, 
			nd.node_id,
			nd.node_type_id,
			nd.node_name,
			nd.type_name AS node_type,
			f.file_name,
			f.extension
	FROM files AS f
		INNER JOIN fg_instance_elements AS e
		ON e.application_id = vr_application_id AND e.element_id = f.owner_id AND 
			e.type = 'File' AND e.deleted = FALSE
		INNER JOIN fg_form_instances AS i
		ON i.application_id = vr_application_id AND i.instance_id = e.instance_id AND i.deleted = FALSE
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i.owner_id AND nd.deleted = FALSE
	WHERE f.owner_type = 'FormElement';
END;
$$ LANGUAGE PLPGSQL;