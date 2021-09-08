DROP FUNCTION IF EXISTS cn_get_direct_childs;

CREATE OR REPLACE FUNCTION cn_get_direct_childs
(
	vr_application_id			UUID,
	vr_node_id					UUID,
	vr_node_type_id				UUID,
	vr_node_type_additional_id 	VARCHAR(20),
	vr_searchable			 	BOOLEAN,
	vr_lower_boundary			FLOAT,
	vr_count				 	INTEGER,
	vr_order_by					VARCHAR(100),
	vr_order_by_desc	 		BOOLEAN,
	vr_search_text				VARCHAR(1000),
	vr_check_access		 		BOOLEAN,
	vr_current_user_id			UUID,
	vr_now				 		TIMESTAMP,
	vr_default_privacy			VARCHAR(50)
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_sort_order 		VARCHAR(10) = 'ASC';
	vr_secondary_order	VARCHAR(100) = '';
	vr_str_searchable 	VARCHAR(100) = '';
	vr_to_be_executed 	VARCHAR;
	vr_permission_types string_pair_table_type[];
	vr_ids_count 		INTEGER;
	vr_temp_ids			UUID[];
	vr_node_ids			UUID[];
	vr_ret_ids			UUID[];
	vr_total_count		BIGINT = 0;
BEGIN
	IF vr_node_type_id IS NULL AND COALESCE(vr_node_type_additional_id, '') <> '' THEN
		vr_node_type_id := cn_fn_get_node_type_id(vr_application_id, vr_node_type_additional_id);
	END IF;

	IF COALESCE(vr_search_text, N'') = N'' THEN
		DROP TABLE IF EXISTS tbl_results_63492;
	
		CREATE TEMP TABLE tbl_results_63492 (node_id UUID);
		
		IF vr_order_by = '"type"' THEN 
			vr_order_by := 'type_name'	;
		ELSEIF vr_order_by = '"date"' THEN
			vr_order_by := 'creation_date';
		ELSEIF vr_order_by = '"name"' THEN
			vr_order_by := 'node_name';
		ELSE 
			vr_order_by := 'sequence_number';
		END IF;
		
		IF vr_order_by_desc = TRUE THEN 
			vr_sort_order := 'DESC';
		END IF;
		
		IF vr_order_by <> 'CreationDate' THEN 
			vr_secondary_order = ', nd.creation_date ASC';
		END IF;
		
		IF vr_searchable IS NOT NULL THEN
			vr_str_searchable := 'COALESCE(nd.searchable, TRUE) = ' || 
				(CASE WHEN vr_searchable = TRUE THEN 'TRUE' ELSE 'FALSE' END) || ' AND ';
		END IF;
		
		vr_to_be_executed :=
			'INSERT INTO tbl_results_63492 (node_id) ' ||
			'SELECT x.node_id ' ||
			'FROM ( ' ||
					'SELECT	ROW_NUMBER() OVER (ORDER BY nd.' || vr_order_by || ' ' ||
								vr_sort_order || vr_secondary_order || ', nd.creation_date ASC, nd.node_id ' || vr_sort_order || ') AS "row_number", ' ||
							'nd.node_id ' ||
					'FROM cn_view_nodes_normal AS nd ' ||
					'WHERE nd.application_id = ''' || vr_application_id::VARCHAR(100) || '''::UUID AND ' ||
						CASE 
							WHEN vr_node_type_id IS NULL THEN '' 
							ELSE 'nd.node_type_id = ''' || vr_node_type_id::VARCHAR(100) || '''::UUID AND '
						END ||
						CASE
							WHEN vr_node_id IS NOT NULL THEN 
								'nd.parent_node_id = ''' || vr_node_id::VARCHAR(100) || '''::UUID AND nd.parent_node_id <> nd.node_id AND '
							ELSE '(nd.parent_node_id IS NULL OR nd.parent_node_id = nd.node_id) AND '
						END ||
						vr_str_searchable || ' ' || 'nd.deleted = FALSE ' ||
				') AS x ' ||
			'ORDER BY x.row_number ASC';
		
		EXECUTE vr_to_be_executed;
		
		vr_node_ids := ARRAY(
			SELECT x.node_id
			FROM tbl_results_63492 AS x
		);
	ELSE
		IF vr_node_id IS NOT NULL THEN
			vr_temp_ids := ARRAY(
				SELECT vr_node_id AS "id"
			);
		
			-- we only need children. so, vr_node_id itself must be discluded
			vr_temp_ids := ARRAY(
				SELECT DISTINCT h.node_id
				FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_temp_ids) AS h
				WHERE h.node_id <> vr_node_id
			);
		END IF;
		
		vr_ids_count := COALESCE(ARRAY_LENGTH(vr_temp_ids, 1), 0)::INTEGER;
		
		vr_node_ids := ARRAY(
			SELECT x.node_id
			FROM (
					SELECT	ROW_NUMBER() OVER (ORDER BY pgroonga_score(nd.tableoid, nd.ctid) DESC, nd.node_id ASC) AS "row_number",
							nd.node_id
					FROM cn_nodes AS nd
						LEFT JOIN UNNEST(vr_temp_ids) AS "t"
						ON "t" = nd.node_id
					WHERE nd.application_id = vr_application_id AND 
						(nd.name &@~ vr_search_text OR nd.additional_id &@~ vr_search_text) AND
						(vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND 
						(vr_ids_count = 0 OR "t" IS NOT NULL) AND 
						(vr_searchable IS NULL OR COALESCE(nd.searchable, TRUE) = vr_searchable) AND nd.deleted = FALSE
				) AS x
			ORDER BY x.row_number ASC
		);
	END IF;
	
	IF COALESCE(vr_check_access, FALSE) = TRUE THEN
		vr_permission_types := ARRAY(
			SELECT ROW('View', vr_default_privacy)
		);
		
		vr_node_ids := ARRAY(
			SELECT "a".id
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_node_ids, 'Node', vr_now, vr_permission_types) AS "a"
		);
	END IF;
	
	vr_total_count := COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0)::BIGINT;
	
	vr_ret_ids := ARRAY(
		SELECT x.id
		FROM UNNEST(vr_node_ids) WITH ORDINALITY AS x("id", seq)
		WHERE x.seq >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.seq ASC
		LIMIT COALESCE(vr_count, 1000000)
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, FALSE, NULL, vr_total_count);
END;
$$ LANGUAGE plpgsql;

