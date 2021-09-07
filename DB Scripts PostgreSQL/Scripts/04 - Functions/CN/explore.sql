DROP FUNCTION IF EXISTS cn_fn_explore;

CREATE OR REPLACE FUNCTION cn_fn_explore
(
	vr_application_id 		UUID,
	vr_base_ids 			UUID[],
	vr_base_type_ids 		UUID[],
	vr_related_id 			UUID,
	vr_related_type_ids		UUID[],
	vr_registration_area 	BOOLEAN,
	vr_tags 				BOOLEAN,
	vr_relations 			BOOLEAN
)
RETURNS TABLE 
(
	base_id					UUID,
    base_type_id			UUID,
    base_name		 		VARCHAR(2000),
    base_type		 		VARCHAR(2000),
    related_id				UUID,
   	related_type_id			UUID,
    related_name		 	VARCHAR(2000),
    related_type		 	VARCHAR(2000),
    related_creation_date	TIMESTAMP,
    is_tag			 		BOOLEAN,
    is_relation		 		BOOLEAN,
    is_registration_area 	BOOLEAN
)
AS
$$
DECLARE
	vr_base_ids_count 			INTEGER;
	vr_base_type_ids_count 		INTEGER = 0;
	vr_related_type_ids_count	INTEGER = 0;
BEGIN
	-- Base === Context --> Folder
	-- Tagged === Related --> Content

	vr_base_ids_count := COALESCE(ARRAY_LENGTH(vr_base_ids, 1), 0);
	
	IF vr_baseIDsCount = 0 THEN 
		vr_base_type_ids_count := COALESCE(ARRAY_LENGTH(vr_base_type_ids, 1), 0);
	END IF;
	
	IF vr_related_id IS NULL THEN 
		vr_related_type_ids_count := COALESCE(ARRAY_LENGTH(vr_related_type_ids, 1), 0);
	END IF;
	
	RETURN QUERY
	SELECT	base.node_id, base.node_type_id, base.node_name, base.type_name,
			related.node_id, related.node_type_id, related.node_name, related.type_name, related.creation_date,
			dt.is_tag, dt.is_relation, dt.is_registration_area
	FROM (
			SELECT r.node_id, r.related_node_id, r.is_related AS is_relation, 
				r.is_tagged AS is_tag, FALSE AS is_registration_area
			FROM cn_fn_get_related_node_ids(vr_application_id, 
				vr_base_ids, vr_base_type_ids, vr_related_type_ids, vr_relations, vr_relations, vr_tags, vr_tags) AS r
			WHERE vr_related_id IS NULL OR r.related_node_id = vr_related_id
			
			UNION ALL
			
			SELECT n.node_id AS context_id, n.area_id AS tagged_id, FALSE, FALSE, TRUE
			FROM cn_nodes AS n
				INNER JOIN cn_nodes AS area
				ON area.application_id = vr_application_id AND area.node_id = n.area_id
			WHERE vr_registration_area = TRUE AND n.application_id = vr_application_id AND 
				(vr_related_id IS NULL OR n.node_id = vr_related_id) AND
				(vr_related_type_ids_count = 0 OR n.node_type_id IN (SELECT UNNEST(vr_related_type_ids))) AND
				(vr_base_ids_count = 0 OR area.node_id IN (SELECT UNNEST(vr_base_ids))) AND
				(vr_base_type_ids_count = 0 OR area.node_type_id IN (SELECT UNNEST(vr_base_type_ids)))
		) AS dt
		INNER JOIN cn_view_nodes_normal AS base
		ON base.application_id = vr_application_id AND base.node_id = dt.node_id
		INNER JOIN cn_view_nodes_normal AS related
		ON related.application_id = vr_application_id AND related.node_id = dt.related_node_id
	WHERE COALESCE(related.status, N'Accepted') = N'Accepted' AND COALESCE(related.searchable, TRUE) = TRUE;
END;
$$ LANGUAGE PLPGSQL;