DROP FUNCTION IF EXISTS cn_fn_get_related_node_ids;

CREATE OR REPLACE FUNCTION cn_fn_get_related_node_ids
(
	vr_application_id			UUID,
	vr_node_ids					UUID[],
	vr_node_type_ids			UUID[],
	vr_related_node_type_ids	UUID[],
	vr_in				 		BOOLEAN,
	vr_out			 			BOOLEAN,
	vr_in_tags			 		BOOLEAN,
	vr_out_tags		 			BOOLEAN
)
RETURNS TABLE 
(
	node_id 		UUID,
	related_node_id	UUID,
	is_related 		BOOLEAN,
	is_tagged 		BOOLEAN
)
AS
$$
DECLARE
	vr_node_ids_count 		INTEGER;
	vr_node_type_ids_count	INTEGER;
	vr_related_types_count 	INTEGER;
BEGIN
	vr_node_ids_count := COALESCE(ARRAY_LENGTH(vr_node_ids), 0);
	vr_node_type_ids_count := COALESCE(ARRAY_LENGTH(vr_node_type_ids), 0);
	vr_related_types_count := COALESCE(ARRAY_LENGTH(vr_related_node_type_ids), 0);
	
	--Source must not be null
	IF vr_node_ids_count = 0 AND vr_node_type_ids_count = 0 THEN 
		vr_node_ids_count := 1;
	END IF;

	RETURN QUERY
	SELECT x.node_id, x.related_node_id, x.is_related, x.is_tagged
	FROM (
			SELECT	ids.node_id, 
					ids.related_node_id, 
					CAST(MAX(ids.is_related) AS boolean) AS is_related, 
					CAST(MAX(ids.is_tagged) AS boolean) AS is_tagged
			FROM (
					SELECT r.node_id, r.related_node_id, TRUE AS is_related, FALSE AS is_tagged
					FROM cn_view_in_related_nodes AS r
					WHERE vr_in = TRUE AND r.application_id = vr_application_id AND 
						(vr_node_ids_count = FALSE OR r.node_id IN (SELECT UNNEST(vr_node_ids))) AND (
							vr_related_types_count = 0 OR 
							r.related_node_type_id IN (SELECT UNNEST(vr_related_node_type_ids))
						)
						
					UNION ALL 
					
					SELECT r.node_id, r.related_node_id, TRUE AS is_related, FALSE AS is_tagged
					FROM cn_view_out_related_nodes AS r
					WHERE vr_out = TRUE AND r.application_id = vr_application_id AND 
						(vr_node_ids_count = 0 OR r.node_id IN (SELECT UNNEST(vr_node_ids))) AND (
							vr_related_types_count = 0 OR 
							r.related_node_type_id IN (SELECT UNNEST(vr_related_node_type_ids))
						)
						
					UNION ALL
						
					SELECT "t".tagged_id, "t".context_id, FALSE AS is_related, TRUE AS is_tagged
					FROM rv_tagged_items AS "t"
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = "t".context_id AND nd.deleted = FALSE AND (
							vr_related_types_count = 0 OR 
							nd.node_type_id IN (SELECT UNNEST(vr_related_node_type_ids))
						)
					WHERE vr_in_tags = TRUE AND "t".application_id = vr_application_id AND 
						(vr_node_ids_count = 0 OR t.tagged_id IN (SELECT UNNEST(vr_node_ids))) AND
						"t".context_type = 'Node'
						
					UNION ALL
						
					SELECT "t".context_id, "t".tagged_id, FALSE AS is_related, TRUE AS is_tagged
					FROM rv_tagged_items AS "t"
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = "t".tagged_id AND nd.deleted = FALSE AND (
							vr_related_types_count = 0 OR 
							nd.node_type_id IN (SELECT UNNEST(vr_related_node_type_ids))
						)
					WHERE vr_out_tags = TRUE AND "t".application_id = vr_application_id AND
						(vr_node_ids_count = 0 OR "t".context_id IN (SELECT UNNEST(vr_node_ids))) AND
						"t".tagged_type ILIKE 'Node%'
				) AS ids
			GROUP BY ids.node_id, ids.related_node_id
		) AS x
		LEFT JOIN cn_nodes AS n
		ON vr_node_type_ids_count > 0 AND n.application_id = vr_application_id AND n.node_id = x.node_id AND
			n.node_type_id IN (SELECT UNNEST(vr_node_type_ids))
	WHERE x.node_id <> x.related_node_id AND (vr_node_type_ids_count = 0 OR n.node_id IS NOT NULL);
END;
$$ LANGUAGE PLPGSQL;