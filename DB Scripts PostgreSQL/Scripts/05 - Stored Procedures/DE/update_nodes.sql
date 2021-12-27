DROP FUNCTION IF EXISTS de_update_nodes;

CREATE OR REPLACE FUNCTION de_update_nodes
(
	vr_application_id			UUID,
	vr_node_type_id				UUID,
	vr_node_type_additional_id	VARCHAR(50),
    vr_nodes					exchange_node_table_type[],
    vr_current_user_id			UUID,
    vr_now		 				TIMESTAMP
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_count	INTEGER;
	vr_ref_1	REFCURSOR;
	vr_ref_2	REFCURSOR;
BEGIN
	IF vr_node_type_id IS NULL THEN
		vr_node_type_id := cn_fn_get_node_type_id(vr_application_id, vr_node_type_additional_id);
	END IF;
	
	DROP TABLE IF EXISTS vr_not_exists_23498;
	DROP TABLE IF EXISTS vr_have_parent_30159;
	DROP TABLE IF EXISTS vr_have_not_parent_50913;
	
	CREATE TEMP TABLE vr_not_exists_23498 OF exchange_node_table_type;
	CREATE TEMP TABLE vr_have_parent_30159 OF exchange_node_table_type;
	CREATE TEMP TABLE vr_have_not_parent_50913 OF exchange_node_table_type;
	
	INSERT INTO vr_not_exists_23498
	SELECT * 
	FROM UNNEST(vr_nodes) AS external_nodes
	WHERE NOT ((external_nodes.node_id IS NULL OR COALESCE(external_nodes.node_additional_id, '') = '') AND
		COALESCE(external_nodes.name, '') = '') AND NOT EXISTS (
			SELECT 1
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND nd.node_type_id = vr_node_type_id AND 
				external_nodes.node_additional_id IS NOT NULL AND nd.additional_id = external_nodes.node_additional_id
			LIMIT 1
		);
		
	vr_count := (SELECT COUNT(*) FROM vr_not_exists_23498);
	
	IF vr_count > 0 THEN
		INSERT INTO cn_nodes (
			application_id,
			node_id,
			node_type_id,
			additional_id,
			"name",
			description,
			tags,
			creator_user_id,
			creation_date,
			deleted
		)
		SELECT 	vr_application_id, 
				COALESCE(ne.node_id, gen_random_uuid()), 
				vr_node_type_id, 
				ne.node_additional_id, 
				gfn_verify_string(ne.name), 
				gfn_verify_string(ne.abstract), 
				gfn_verify_string(ne.tags), 
				vr_current_user_id, 
				vr_now, 
				FALSE
		FROM vr_not_exists_23498 AS ne;
	END IF;
	
	IF EXISTS (
		SELECT 1 
		FROM UNNEST(vr_nodes) AS nd
		WHERE COALESCE(nd.node_additional_id, '') <> '' AND COALESCE(nd.name, '') <> ''
		LIMIT 1
	) THEN
		UPDATE cn_nodes
		SET "name" = gfn_verify_string(external_nodes.name),
			tags = COALESCE(gfn_verify_string(external_nodes.tags), nd.tags),
			description = COALESCE(gfn_verify_string(external_nodes.abstract), nd.description)
		FROM UNNEST(vr_nodes) AS external_nodes
			INNER JOIN cn_nodes AS nd
			ON nd.additional_id = external_nodes.node_additional_id
		WHERE nd.application_id = vr_application_id AND 
			COALESCE(external_nodes.node_additional_id, '') <> '' AND
			nd.node_type_id = vr_node_type_id AND COALESCE(external_nodes.name, '') <> '';
	END IF;
	
	-- Update Sequence Number
	UPDATE cn_nodes
	SET sequence_number = x.row_num
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT 1) ASC) AS row_num,
					n.*
			FROM UNNEST(vr_nodes) AS n
		) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_type_id = vr_node_type_id AND
			COALESCE(nd.additional_id, '') <> '' AND nd.additional_id = x.node_additional_id;
	-- end of Update Sequence Number
	
	INSERT INTO vr_have_parent_30159 (
		node_additional_id, 
		parent_additional_id
	)
	SELECT 	nd.node_additional_id, 
			nd.parent_additional_id
	FROM UNNEST(vr_nodes) AS nd
	WHERE COALESCE(nd.node_additional_id, '') <> '' AND COALESCE(nd.parent_additional_id, '') <> '';
	
	IF EXISTS (SELECT 1 FROM vr_have_parent_30159 LIMIT 1) THEN
		UPDATE cn_nodes
		SET parent_node_id = ot.node_id,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM vr_have_parent_30159 AS external_nodes
			INNER JOIN cn_nodes AS nd
			ON nd.additional_id = external_nodes.node_additional_id
			INNER JOIN cn_nodes AS ot
			ON ot.additional_id = external_nodes.parent_additional_id
		WHERE nd.application_id = vr_application_id AND ot.application_id = vr_application_id AND
			nd.node_type_id = vr_node_type_id AND ot.node_type_id = vr_node_type_id;
	END IF;
	
	INSERT INTO vr_have_not_parent_50913 (
		node_additional_id, 
		parent_additional_id
	)
	SELECT 	nd.node_additional_id, 
			nd.parent_additional_id
	FROM UNNEST(vr_nodes) AS nd
	WHERE COALESCE(nd.node_additional_id, '') <> '' AND COALESCE(nd.parent_additional_id, '') = '';
	
	IF EXISTS (SELECT 1 FROM vr_have_not_parent_50913 LIMIT 1) THEN
		UPDATE cn_nodes
		SET parent_node_id = NULL,
			last_modifierUser_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM vr_have_not_parent_50913 AS external_nodes
			INNER JOIN cn_nodes AS nd
			ON nd.additional_id = external_nodes.node_additional_id
		WHERE nd.application_id = vr_application_id AND nd.node_type_id = vr_node_type_id;
	END IF;
	
	OPEN vr_ref_1 FOR
	SELECT 1::INTEGER;
	RETURN NEXT vr_ref_1;
	
	OPEN vr_ref_2 FOR
	SELECT n.node_id AS "id"
	FROM vr_not_exists_23498 AS n
	WHERE n.node_id IS NOT NULL;
	RETURN NEXT vr_ref_2;
END;
$$ LANGUAGE plpgsql;

