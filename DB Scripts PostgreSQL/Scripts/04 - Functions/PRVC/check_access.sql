DROP FUNCTION IF EXISTS prvc_fn_check_access;

CREATE OR REPLACE FUNCTION prvc_fn_check_access
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_object_ids		UUID[],
	vr_object_type		VARCHAR(50),
	vr_now			 	TIMESTAMP,
	vr_permission_types	string_pair_table_type[] -- first_value: type, second_value: default_privacy
)
RETURNS TABLE (
	"id"	UUID,
	"type"	VARCHAR(50)
)
AS
$$
DECLARE
	vr_yesterday	TIMESTAMP;
	vr_user_conf	INTEGER;
	vr_group_ids 	UUID[];
BEGIN
	DROP TABLE IF EXISTS vr_item_ids_20498;
	DROP TABLE IF EXISTS vr_nodes_29867;
	DROP TABLE IF EXISTS vr_ids_04983;
	DROP TABLE IF EXISTS vr_values_20743;
	
	IF vr_now IS NOT NULL THEN 
		vr_yesterday := vr_now - INTERVAL '1 DAYS';
	END IF;

	-- Find Confidentiality of the User
	IF vr_user_id IS NULL THEN 
		vr_user_conf := 0;
	ELSE
		vr_user_conf := COALESCE(
			(
				SELECT "c".level_id 
				FROM prvc_view_confidentialities AS "c"
				WHERE "c".application_id = vr_application_id  AND "c".object_id = vr_user_id
				LIMIT 1
			),
			COALESCE((
				SELECT MIN("c".level_id) 
				FROM prvc_confidentiality_levels AS "c"
				WHERE "c".application_id = vr_application_id AND "c".deleted = FALSE
			), 0)
		);
	END IF;
	-- end of Find Confidentiality of the User

	vr_group_ids := ARRAY(
		SELECT nm.node_id
		FROM cn_view_node_members AS nm
		WHERE nm.application_id = vr_application_id AND nm.user_id = vr_user_id AND nm.is_pending = FALSE
	);

	CREATE TEMP TABLE vr_item_ids_20498 ("id" UUID, "level" INTEGER);

	INSERT INTO vr_item_ids_20498("id", "level")
	SELECT x.node_id, MIN(COALESCE(x.level, 0)) + 1
	FROM cn_fn_get_nodes_hierarchy(vr_application_id, vr_group_ids) AS x
	GROUP BY x.node_id;


	IF COALESCE(vr_object_type, '') <> 'Node' THEN
		RETURN QUERY
		SELECT o.value, "p".first_value
		FROM (
				SELECT "ref".object_id AS "id", "ref".type, "ref".allow
				FROM (
						SELECT	ROW_NUMBER() OVER (PARTITION BY x.object_id, x.type
									ORDER BY x.level ASC, x.allow ASC) AS "row_number",
								x.object_id,
								x.type,
								x.allow
						FROM (
								SELECT	o.value AS object_id, 
										"a".permission_type AS "type", 
										COALESCE(i.level, 0) AS "level", 
										"a".allow
								FROM vr_object_ids AS o
									INNER JOIN prvc_audience AS "a"
									ON "a".application_id = vr_application_id AND "a".object_id = o.value AND 
										"a".deleted = FALSE AND
										"a".permission_type IN (
											SELECT ("p").first_value FROM UNNEST(vr_permission_types) AS "p"
										) AND
										("a".expiration_date IS NULL OR (
											vr_yesterday IS NOT NULL AND "a".expiration_date >= vr_yesterday
										))
									LEFT JOIN prvc_settings AS s
									ON s.application_id = vr_application_id AND s.object_id = o.value
									LEFT JOIN prvc_confidentiality_levels AS cl
									ON cl.application_id = vr_application_id AND 
										cl.id = s.confidentiality_id AND cl.deleted = FALSE
									LEFT JOIN vr_item_ids_20498 AS i
									ON i.id = a.role_id
								WHERE (i.id IS NOT NULL OR "a".role_id = vr_user_id) AND
									(s.object_id IS NULL OR 
									 	COALESCE(s.calculate_hierarchy, FALSE) = TRUE OR 
									 	COALESCE(i.level, 0) <= 1
									) AND
									vr_user_conf >= COALESCE(cl.level_id, 0)
							) AS x
					) AS "ref"
				WHERE "ref".row_number = 1
			) AS "a"
			RIGHT JOIN vr_object_ids AS o
			CROSS JOIN UNNEST(vr_permission_types) AS "p"
			LEFT JOIN prvc_default_permissions AS d
			ON d.application_id = vr_application_id AND d.object_id = o.value AND d.permission_type = "p".first_value
			ON o.value = "a".id AND "p".first_value = "a".type
		WHERE COALESCE("a".allow, FALSE) = TRUE OR (
			"a".id IS NULL AND COALESCE(COALESCE(d.default_value, "p".second_value), '') = 'Public'
		);
	ELSE
		CREATE TEMP TABLE vr_nodes_29867 (
			node_id 				UUID, 
			node_type_id 			UUID, 
			document_tree_node_id	UUID, 
			document_tree_id 		UUID, 
			permission_type 		VARCHAR(50),  
			default_value 			BOOLEAN, 
			default_n 				BOOLEAN, 
			default_nt 				BOOLEAN, 
			default_dtn 			BOOLEAN, 
			default_dt 				BOOLEAN,
			n_allow 				BOOLEAN, 
			nt_allow 				BOOLEAN, 
			dtn_allow 				BOOLEAN, 
			dt_allow 				BOOLEAN
		);

		INSERT INTO vr_nodes_29867 (node_id, node_type_id, document_tree_node_id, 
							  document_tree_id, permission_type, default_value)
		SELECT nd.node_id, nd.node_type_id, nd.document_tree_node_id, tn.tree_id, 
			"p".first_value, prvc_fn_default_value_to_boolean("p".second_value)
		FROM vr_object_ids AS o
			CROSS JOIN UNNEST(vr_permission_types) AS "p"
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = o.value
			LEFT JOIN dct_tree_nodes AS tn
			ON nd.document_tree_node_id IS NOT NULL AND tn.application_id = vr_application_id AND 
				tn.tree_node_id = nd.document_tree_node_id AND tn.deleted = FALSE
			LEFT JOIN dct_trees AS "t"
			ON nd.document_tree_node_id IS NOT NULL AND "t".application_id = vr_application_id AND 
				"t".tree_id = tn.tree_id AND "t".deleted = FALSE;
		
		CREATE TEMP TABLE vr_ids_04983 (
			"id" 			UUID, 
			"type" 			VARCHAR(20), 
			default_value 	BOOLEAN, 
			PRIMARY KEY ("id", "type")
		);
		
		INSERT INTO vr_ids_04983 ("id", "type", default_value)
		SELECT DISTINCT i.value, pt.first_value, prvc_fn_default_value_to_boolean(dp.default_value)
		FROM (
				SELECT x.value FROM vr_object_ids AS x
				UNION ALL 
				SELECT DISTINCT n.node_type_id FROM vr_nodes_29867 AS n WHERE n.node_type_id IS NOT NULL
				UNION ALL
				SELECT DISTINCT n.document_tree_node_id FROM vr_nodes_29867 AS n WHERE n.document_tree_node_id IS NOT NULL
				UNION ALL
				SELECT DISTINCT n.document_tree_id FROM vr_nodes_29867 AS n WHERE n.document_tree_id IS NOT NULL
			) AS i
			CROSS JOIN UNNEST(vr_permission_types) AS pt
			LEFT JOIN prvc_default_permissions AS dp
			ON dp.application_id = vr_application_id AND dp.object_id = i.value AND dp.permission_type = pt.first_value;
			
		UPDATE vr_nodes_29867 SET default_n = ids.default_value
		FROM vr_nodes_29867 AS n INNER JOIN vr_ids_04983 AS ids ON ids.id = n.node_id AND ids.type = n.permission_type;
			
		UPDATE vr_nodes_29867 SET default_nt = ids.default_value
		FROM vr_nodes_29867 AS n INNER JOIN vr_ids_04983 AS ids ON ids.id = n.node_type_id AND ids.type = n.permission_type;
		
		UPDATE vr_nodes_29867 SET default_dtn = ids.default_value
		FROM vr_nodes_29867 AS n INNER JOIN vr_ids_04983 AS ids ON ids.id = n.document_tree_node_id AND ids.type = n.permission_type;
		
		UPDATE vr_nodes_29867 SET default_dt = ids.default_value
		FROM vr_nodes_29867 AS n INNER JOIN vr_ids_04983 AS ids ON ids.id = n.document_tree_id AND ids.type = n.permission_type;
		
		CREATE TEMP TABLE vr_values_20743 ("id" UUID, "type" VARCHAR(20), allow BOOLEAN);

		INSERT INTO vr_values_20743 ("id", "type", allow)
		SELECT "ref".object_id, "ref".type, "ref".allow
		FROM (
				SELECT	ROW_NUMBER() OVER (PARTITION BY x.object_id, x.type
							ORDER BY x.level ASC, x.allow ASC) AS "row_number",
						x.object_id,
						x.type,
						x.allow
				FROM (
						SELECT	o.value AS object_id, 
								"a".permission_type AS "type", 
								COALESCE(i.level, 0) AS "level", 
								"a".allow
						FROM (
								SELECT DISTINCT ids.id AS "value"
								FROM vr_ids_04983 AS ids
							) AS o
							LEFT JOIN prvc_settings AS s
							ON s.application_id = vr_application_id AND s.object_id = o.value
							INNER JOIN prvc_audience AS "a"
							ON "a".application_id = vr_application_id AND "a".object_id = o.value AND "a".deleted = FALSE AND
								"a".permission_type IN (SELECT "p".first_value FROM UNNEST(vr_permission_types) AS "p") AND
								("a".expiration_date IS NULL OR (vr_yesterday IS NOT NULL AND "a".expiration_date >= vr_yesterday))
							LEFT JOIN vr_item_ids_20498 AS i
							ON i.id = "a".role_id
						WHERE (i.id IS NOT NULL OR "a".role_id = vr_user_id) AND 
							(s.object_id IS NULL OR COALESCE(s.calculate_hierarchy, FALSE) = TRUE OR COALESCE(i.level, 0) <= 1)
					) AS x
			) AS "ref"
		WHERE "ref".row_number = 1;
		
		UPDATE vr_nodes_29867
		SET n_allow = v.allow
		FROM vr_nodes_29867 AS n
			INNER JOIN vr_values_20743 AS v
			ON v.id = n.node_id AND v.type = n.permission_type;
			
		UPDATE vr_nodes_29867
		SET nt_allow = v.allow
		FROM vr_nodes_29867 AS n
			INNER JOIN vr_values_20743 AS v
			ON v.id = n.node_type_id AND v.type = n.permission_type;
			
		UPDATE vr_nodes_29867
		SET dtn_allow = v.allow
		FROM vr_nodes_29867 AS n
			INNER JOIN vr_values_20743 AS v
			ON v.id = n.document_tree_node_id AND v.type = n.permission_type;
			
		UPDATE vr_nodes_29867
		SET dt_allow = v.allow
		FROM vr_nodes_29867 AS n
			INNER JOIN vr_values_20743 AS v
			ON v.id = n.document_tree_id AND v.type = n.permission_type;
		
		RETURN QUERY
		SELECT	n.node_id AS "id", 
				n.permission_type AS "type"
		FROM vr_nodes_29867 AS n
			LEFT JOIN prvc_view_confidentialities AS s
			ON s.application_id = vr_application_id AND s.object_id = n.node_id
		WHERE vr_user_conf >= COALESCE(s.level_id, 0) AND 
			COALESCE(COALESCE(
				prvc_fn_check_node_permission(n.n_allow, n.nt_allow, n.dtn_allow, n.dt_allow),
				prvc_fn_check_node_permission(n.default_n, n.default_nT, n.default_dtn, n.default_dt)
			), n.default_value) = TRUE;
	END IF;
END;
$$ LANGUAGE PLPGSQL;