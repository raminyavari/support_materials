DROP FUNCTION IF EXISTS cn_explore;

CREATE OR REPLACE FUNCTION cn_explore
(
	vr_application_id		UUID,
	vr_base_id				UUID,
	vr_related_id			UUID,
	vr_base_type_ids		guid_table_type[],
	vr_related_type_ids		guid_table_type[],
	vr_second_level_node_id	UUID,
	vr_registration_area 	BOOLEAN,
	vr_tags			 		BOOLEAN,
	vr_relations		 	BOOLEAN,
	vr_lower_boundary	 	INTEGER,
	vr_count			 	INTEGER,
	vr_order_by				VARCHAR(100),
	vr_order_by_desc	 	BOOLEAN,
	vr_search_text		 	VARCHAR(1000),
	vr_check_access	 		BOOLEAN,
	vr_current_user_id		UUID,
	vr_now			 		TIMESTAMP,
	vr_default_privacy		VARCHAR(50)
)
RETURNS TABLE (
	total_count				INTEGER,
	base_id					UUID, 
	base_type_id			UUID, 
	base_name				VARCHAR, 
	base_type				VARCHAR,
	related_id				UUID, 
	related_type_id			UUID, 
	related_name			VARCHAR, 
	related_type			VARCHAR,
	related_creation_date	TIMESTAMP, 
	is_tag					BOOLEAN, 
	is_relation				BOOLEAN, 
	is_registration_area	BOOLEAN
)
AS
$$
DECLARE
	vr_ar_base_type_ids	UUID[];
	vr_base_ids			UUID[];
	vr_second_level_ids	UUID[];
	vr_sort_order		VARCHAR(10) DEFAULT 'ASC';
	vr_permission_types string_pair_table_type[];
	vr_temp_ids			UUID[];
	vr_to_be_executed 	VARCHAR;
BEGIN
	vr_ar_base_type_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_base_type_ids) AS x
	);

	IF vr_order_by = 'Type' THEN 
		vr_order_by := 'related_type';
	ELSEIF vr_order_by = 'Date' THEN 
		vr_order_by := 'related_creation_date';
	ELSE 
		vr_order_by := 'related_name';
	END IF;
	
	IF vr_order_by_desc = TRUE THEN
		vr_sort_order := 'DESC';
	END IF;
	
	IF vr_base_id IS NOT NULL THEN
		vr_base_ids := ARRAY(
			SELECT vr_base_id
		);
	
		IF COALESCE(vr_search_text, '') <> '' THEN
			vr_base_ids := ARRAY(
				SELECT vr_base_id
				
				UNION ALL
				
				SELECT DISTINCT h.node_id
				FROM UNNEST(vr_base_ids) AS b
					RIGHT JOIN cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_base_ids) AS h
					ON h.node_id = b
				WHERE b IS NULL AND h.node_id <> vr_base_id
			);
		END IF;
	END IF;

	DROP TABLE IF EXISTS items_99238;
		
	CREATE TEMP TABLE items_99238 (
		base_id 				UUID,
		base_type_id 			UUID, 
		base_name 				VARCHAR, 
		base_type 				VARCHAR, 
		related_id 				UUID, 
		related_type_id 		UUID, 
		related_name 			VARCHAR,
		related_type 			VARCHAR, 
		related_creation_date 	TIMESTAMP,
		is_tag 					BOOLEAN, 
		is_relation 			BOOLEAN, 
		is_registration_area	BOOLEAN,
		PRIMARY KEY (base_id, related_id)
	);

	INSERT INTO items_99238
	SELECT	rf.base_id,
			MAX(rf.base_type_id::VARCHAR(100))::UUID,
			MAX(rf.base_name),
			MAX(rf.base_type),
			rf.related_id,
			MAX(rf.related_type_id::VARCHAR(100))::UUID,
			MAX(rf.related_name),
			MAX(rf.related_type),
			MAX(rf.related_creation_date),
			MAX(rf.is_tag::INTEGER)::BOOLEAN,
			MAX(rf.is_relation::INTEGER)::BOOLEAN,
			MAX(rf.is_registration_area::INTEGER)::BOOLEAN
	FROM cn_fn_explore(vr_application_id, vr_base_ids, vr_ar_base_type_ids, 
		vr_related_id, vr_related_type_ids, vr_registration_area, vr_tags, vr_relations) AS rf
	GROUP BY rf.base_id, rf.related_id;
	
	IF vr_second_level_node_id IS NOT NULL THEN
		vr_second_level_ids := ARRAY(
			SELECT vr_second_level_node_id
		);
		
		WITH rf AS (
			SELECT i.base_id, i.related_id
			FROM items_99238 AS i
			LEFT JOIN (
					SELECT r.node_id, r.related_node_id
					FROM cn_fn_get_related_node_ids(vr_application_id, vr_second_level_ids, NULL, vr_related_type_ids, 
													vr_relations, vr_relations, vr_tags, vr_tags) AS r
				) AS x
				ON x.related_node_id = i.related_id
			WHERE x.related_node_id IS NULL
		)
		DELETE FROM items_99238
		USING rf
		WHERE items_99238.base_id = rf.base_id AND items_99238.related_id = rf.related_id;
	END IF;
	
	IF vr_check_access = TRUE THEN
		vr_permission_types := ARRAY(
			SELECT ROW('View', vr_default_privacy)
		);
	
		vr_temp_ids := ARRAY(
			SELECT i.related_id
			FROM items_99238 AS i
		);
	
		WITH rf AS (
			SELECT i.base_id, i.related_id
			FROM items_99238 AS i
				LEFT JOIN prvc_fn_check_access(vr_application_id, vr_current_user_id, 
					vr_temp_ids, 'Node', vr_now, vr_permission_types) AS x
				ON x.id = i.related_id
			WHERE x.id IS NULL
		)
		DELETE FROM items_99238
		USING rf
		WHERE items_99238.base_id = rf.base_id AND items_99238.related_id = rf.related_id;
	END IF;
	
	IF COALESCE(vr_search_text, '') = '' THEN
		vr_to_be_executed := 
			'WITH "data" AS ( ' ||
				'SELECT	ROW_NUMBER() OVER ( ' ||
							'ORDER BY 	i.' || vr_order_by || ' ' || vr_sort_order || ', ' ||
										'i.related_id ASC ' ||
						') AS "row_number", ' ||
						'i.* ' ||
				'FROM items_99238 AS i ' ||
			'), ' ||
			'total AS (SELECT COUNT(d.related_id) AS total_count FROM "data" AS d) ' ||
			'SELECT	"t".total_count::INTEGER, x.base_id, x.base_type_id, x.base_name, x.base_type, ' ||
					'x.related_id, x.related_type_id, x.related_name, x.related_type, ' ||
					'x.related_creation_date, x.is_tag, x.is_relation, x.is_registration_area ' ||
			'FROM "data" AS x CROSS JOIN total AS "t" ' ||
			'WHERE x.row_number >= ' || COALESCE(vr_lower_boundary, 0)::VARCHAR || ' ' ||
			'ORDER BY x.row_number ASC ' ||
			'LIMIT ' || COALESCE(vr_count, 100)::VARCHAR;
	
		RETURN QUERY
		EXECUTE vr_to_be_executed;
	ELSE
		RETURN QUERY
		WITH "data" AS (
			SELECT	ROW_NUMBER() OVER (
						ORDER BY 	pgroonga_score(nd.tableoid, nd.ctid) DESC, 
									nd.node_id ASC
					) AS "row_number",
					rf.*
			FROM (
					SELECT	MAX(i.base_id::VARCHAR(100))::UUID AS base_id,
							MAX(i.base_type_id::VARCHAR(100))::UUID AS base_type_id,
							MAX(i.base_name) AS base_name,
							MAX(i.base_type) AS base_type,
							i.related_id,
							MAX(i.related_type_id::VARCHAR(100))::UUID AS related_type_id,
							MAX(i.related_name) AS related_name,
							MAX(i.related_type) AS related_type,
							MAX(i.related_creation_date) AS related_creation_date,
							MAX(i.is_tag::INTEGER)::BOOLEAN AS is_tag,
							MAX(i.is_relation::INTEGER)::BOOLEAN AS is_relation,
							MAX(i.is_registration_area::INTEGER)::BOOLEAN AS is_registration_area
					FROM items_99238 AS i
					GROUP BY i.related_id
				) AS rf
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = rf.related_id AND (
						nd.name &@~ vr_search_text OR nd.additional_id &@~ vr_search_text
					)
		),
		total AS (
			SELECT COUNT(d.related_id) AS total_count
			FROM "data" AS d
		)
		SELECT	"t".total_count::INTEGER,
				x.base_id, 
				x.base_type_id, 
				x.base_name, 
				x.base_type,
				x.related_id, 
				x.related_type_id, 
				x.related_name, 
				x.related_type,
				x.related_creation_date, 
				x.is_tag, 
				x.is_relation, 
				x.is_registration_area
		FROM "data" AS x
			CROSS JOIN total AS "t"
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
		LIMIT COALESCE(vr_count, 100);
	END IF;
END;
$$ LANGUAGE plpgsql;

