DROP FUNCTION IF EXISTS cn_p_initialize_node_types;

CREATE OR REPLACE FUNCTION cn_p_initialize_node_types
(
	vr_application_id	UUID,
	vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE 
	vr_cur_node_types_count	INTEGER;
	vr_user_id 				UUID;
	vr_knowledge_type_id 	UUID;
	vr_result	 			INTEGER;
BEGIN
	vr_result := 0;
	
	IF vr_now IS NULL THEN
		vr_now := NOW();
	END IF;
	
	vr_cur_node_types_count := COALESCE((
		SELECT COUNT(*) 
		FROM cn_node_types AS x
		WHERE x.application_id = vr_application_id AND gfn_is_numeric(x.additional_id) = TRUE
	), 0)::INTEGER;
	
	IF vr_cur_node_types_count > 2 THEN
		vr_result = 1;
		RETURN vr_result;
	END IF;

	vr_user_id := (
		SELECT un.user_id
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND LOWER(un.username) = N'admin'
		LIMIT 1
	);

	DROP TABLE IF EXISTS vr_node_types_56204;

	CREATE TEMP TABLE vr_node_types_56204 (additional_id VARCHAR(20), "name" VARCHAR(500));

	INSERT INTO vr_node_types_56204 (additional_id, "name")
	VALUES ('1', N'حوزه دانش'), ('2', N'پروژه'), ('3', N'فرآيند'), ('4', N'انجمن دانايي'), 
		('5', N'دانش'), ('6', N'واحد سازمانی'), ('7', N'تخصص'), ('11', N'تگ');

	INSERT INTO cn_node_types (
		application_id,
		node_type_id, 
		"name", 
		deleted, 
		creator_user_id, 
		creation_date,
		additional_id
	) 
	SELECT  vr_application_id, 
			gen_random_uuid(), 
			gfn_verify_string(nt.name), 
			FALSE, 
			vr_user_id, 
			vr_now, 
			nt.additional_id
	FROM vr_node_types_56204 AS nt
		LEFT JOIN cn_node_types AS "t"
		ON "t".application_id = vr_application_id AND "t".additional_id = Nt.additional_id
	WHERE "t".node_type_id IS NULL;
	
	DROP TABLE vr_knowledge_types_46294;
	
	CREATE TEMP TABLE vr_knowledge_types_46294 (additional_id VARCHAR(20), "name" VARCHAR(500));

	INSERT INTO vr_knowledge_types_46294 (additional_id, "name")
	VALUES ('8', N'مهارت'), ('9', N'تجربه'), ('10', N'مستند');
	
	vr_knowledge_type_id := (
		SELECT x.node_type_id
		FROM cn_node_types AS x
		WHERE x.application_id = vr_application_id AND x.additional_id = '5'
		LIMIT 1
	);
	
	IF vr_knowledge_type_id IS NOT NULL THEN
		INSERT INTO cn_node_types (
			application_id,
			node_type_id, 
			"name", 
			deleted, 
			creator_user_id, 
			creation_date,
			additional_id,
			parent_id
		) 
		SELECT  vr_application_id, 
				gen_random_uuid(), 
				gfn_verify_string(nt.name), 
				FALSE, 
				vr_user_id, 
				vr_now, 
				nt.additional_id,
				vr_knowledge_type_id
		FROM vr_knowledge_types_46294 AS nt
			LEFT JOIN cn_node_types AS "t"
			ON t.application_id = vr_application_id AND "t".additional_id = Nt.additional_id
		WHERE "t".node_type_id IS NULL;
	END IF;

	vr_result := 1;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
