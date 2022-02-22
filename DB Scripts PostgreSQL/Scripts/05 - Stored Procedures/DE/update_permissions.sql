DROP FUNCTION IF EXISTS de_update_permissions;

CREATE OR REPLACE FUNCTION de_update_permissions
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_items			exchange_permission_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result_1	INTEGER;
	vr_result_2	INTEGER;
	vr_result_3	INTEGER;
BEGIN
	DROP TABLE IF EXISTS vr_values_98375;

	CREATE TEMP TABLE vr_values_98375 (
		object_id 		UUID, 
		role_id			UUID, 
		permission_type	VARCHAR(50), 
		allow 			BOOLEAN,
		drop_all 		BOOLEAN
	);
	
	
	INSERT INTO vr_values_98375 (
		object_id, 
		role_id, 
		permission_type, 
		allow, 
		drop_all
	)
	SELECT DISTINCT 
		nd.node_id, 
		COALESCE(un.user_id, grp.node_id), 
		i.permission_type, 
		i.allow, 
		i.drop_all
	FROM UNNEST(vr_items) AS i
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.type_additional_id = i.node_type_additional_id AND
			nd.node_additional_id = i.node_additional_id
		LEFT JOIN cn_view_nodes_normal AS grp
		ON grp.application_id = vr_application_id AND grp.type_additional_id = i.group_type_additional_id AND
			grp.node_additional_id = i.group_additional_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(i.username)
	WHERE ((grp.node_id IS NOT NULL OR un.user_id IS NOT NULL) AND i.permission_type IS NOT NULL) OR i.drop_all = TRUE;
	
	
	-- Part 1: Drop All
	UPDATE prvc_audience
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM prvc_audience AS "a"
		INNER JOIN (
			SELECT DISTINCT v.object_id
			FROM vr_values_98375 AS v
			WHERE v.drop_all = TRUE
		) AS rf
		ON rf.object_id = "a".object_id
	WHERE "a".application_id = vr_application_id;
	-- end of Part 1: Drop All
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	-- Part 2: Update Existing Items
	UPDATE prvc_audience
	SET allow = COALESCE(v.allow, FALSE),
		expiration_date = NULL,
		deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM vr_values_98375 AS v
		INNER JOIN prvc_audience AS "a"
		ON "a".application_id = vr_application_id AND "a".object_id = v.object_id AND 
			"a".role_id = v.role_id AND "a".permission_type = v.permission_type;
	-- end of Part 2: Update Existing Items
	
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;
	
	-- Part 3: Add New Items
	INSERT INTO prvc_audience (
		application_id,
		object_id,
		role_id,
		permission_type,
		allow,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT 	vr_application_id, 
			v.object_id, 
			v.role_id, 
			v.permission_type, 
			COALESCE(v.allow, FALSE), 
			vr_current_user_id, 
			vr_now, 
			FALSE	
	FROM vr_values_98375 AS v
		LEFT JOIN prvc_audience AS "a"
		ON "a".application_id = vr_application_id AND "a".object_id = v.object_id AND 
			"a".role_id = v.role_id AND "a".permission_type = v.permission_type
	WHERE v.object_id IS NOT NULL AND v.role_id IS NOT NULL AND 
		v.permission_type IS NOT NULL AND "a".object_id IS NULL;
	-- end of Part 3: Add New Items;
	
	GET DIAGNOSTICS vr_result_3 := ROW_COUNT;

	RETURN COALESCE(vr_result_1, 0)::INTEGER + COALESCE(vr_result_2, 0)::INTEGER + COALESCE(vr_result_3, 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

