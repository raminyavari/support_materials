

DROP PROCEDURE IF EXISTS _cn_p_initialize_node_types;

CREATE OR REPLACE PROCEDURE _cn_p_initialize_node_types
(
	vr_application_id	UUID,
	vr_now				TIMESTAMP,
	INOUT vr_result	 	INTEGER
)
AS
$$
DECLARE 
	vr_cur_node_types_count	INTEGER;
	vr_user_id 				UUID;
	vr_knowledge_type_id 	UUID;
BEGIN
	vr_result := 0;
	
	IF vr_now IS NULL THEN
		vr_now := NOW();
	END IF;
	
	vr_cur_node_types_count := COALESCE((
		SELECT COUNT(*) 
		FROM cn_node_types 
		WHERE application_id = vr_application_id AND gfn_is_numeric(additional_id) = TRUE
	), 0)::INTEGER;
	
	IF vr_cur_node_types_count > 2 THEN
		vr_result = 1;
		RETURN;
	END IF;

	vr_user_id := (
		SELECT user_id
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND LOWER(un.username) = N'admin'
		LIMIT 1
	);

	CREATE TEMP TABLE vr_node_types (additional_id VARCHAR(20), "name" VARCHAR(500));

	INSERT INTO vr_node_types (additional_id, "name")
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
	FROM vr_node_types AS nt
		LEFT JOIN cn_node_types AS "t"
		ON "t".application_id = vr_application_id AND "t".additional_id = Nt.additional_id
	WHERE "t".node_type_id IS NULL;
	
	CREATE TEMP TABLE vr_knowledge_types (additional_id VARCHAR(20), "name" VARCHAR(500));

	INSERT INTO vr_knowledge_types (additional_id, "name")
	VALUES ('8', N'مهارت'), ('9', N'تجربه'), ('10', N'مستند');
	
	vr_knowledge_type_id := (
		SELECT node_type_id
		FROM cn_node_types
		WHERE application_id = vr_application_id AND additional_id = '5'
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
		FROM vr_knowledge_types AS nt
			LEFT JOIN cn_node_types AS "t"
			ON t.application_id = vr_application_id AND "t".additional_id = Nt.additional_id
		WHERE "t".node_type_id IS NULL;
	END IF;

	vr_result := 1;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;



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
	vr_result INTEGER = 0;
BEGIN
	CALL _cn_p_initialize_node_types(vr_application_id, vr_now, vr_result);	
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

