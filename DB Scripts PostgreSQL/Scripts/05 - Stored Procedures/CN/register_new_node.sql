DROP FUNCTION IF EXISTS cn_register_new_node;

CREATE OR REPLACE FUNCTION cn_register_new_node
(
	vr_application_id			UUID,
	vr_node_id					UUID,
    vr_node_type_id				UUID,
    vr_additional_id_main 		VARCHAR(300),
    vr_additional_id	 		VARCHAR(50),
    vr_parent_node_id			UUID,
    vr_document_tree_node_id	UUID,
    vr_previous_version_id		UUID,
	vr_name			 			VARCHAR(255),
	vr_description	 			VARCHAR,
	vr_tags			 			VARCHAR,
	vr_creator_user_id			UUID,
	vr_creation_date	 		TIMESTAMP,
	vr_contributors				guid_float_table_type[],
	vr_owner_id					UUID,
	vr_workflow_id				UUID,
	vr_admin_area_id			UUID,
	vr_form_instance_id			UUID,
	vr_wf_director_node_id		UUID,
	vr_wf_director_user_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_searchable		BOOLEAN DEFAULT TRUE;
	vr_doc_ids			UUID[];
	vr_form_id 			UUID;
	vr_instance_id 		UUID;
	vr_instances 		form_instance_table_type[];
	vr_form_elements 	string_pair_table_type[];
	vr_message 			VARCHAR;
	vr_result			INTEGER;
BEGIN
	-- Set searchability 
	SELECT vr_searchable = (
		CASE
			WHEN COALESCE(s.is_knowledge, FALSE) = FALSE OR 
				kt.searchable_after = 'Registration' THEN TRUE
			ELSE FALSE
		END
	)
	FROM cn_services AS s
		LEFT JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = s.node_type_id
	WHERE s.application_id = vr_application_id AND 
		s.node_type_id = vr_node_type_id AND s.is_knowledge = TRUE
	LIMIT 1;
	
	SELECT 	vr_result = x.result,
			vr_message = x.error_message::VARCHAR
	FROM cn_p_add_node(vr_application_id, vr_node_id, vr_additional_id, vr_node_type_id, NULL, 
					   vr_document_tree_node_id, vr_previous_version_id, vr_name, vr_description, vr_tags, 
					   vr_searchable, vr_creator_user_id, vr_creation_date, vr_parent_node_id, vr_owner_id, NULL) AS x
	LIMIT 1;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception(vr_result, COALESCE(vr_message, 'NodeCreationFailed'));
		RETURN -1;
	END IF;
	
	UPDATE cn_nodes AS nd
	SET additional_id_main = vr_additional_id_main,
		area_id = vr_admin_area_id
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	-- Hide Previous Version
	IF vr_searchable = TRUE AND vr_previous_version_id IS NOT NULL THEN
		UPDATE cn_nodes AS nd
		SET searchable = FALSE
		WHERE nd.application_id = vr_application_id AND 
			nd.node_id = vr_previous_version_id AND nd.deleted = FALSE;
	END IF;
	-- end of Hide Previous Version
	
	IF vr_form_instance_id IS NOT NULL THEN
		UPDATE fg_form_instances AS i
		SET owner_id = vr_node_id,
			is_temporary = FALSE
		WHERE i.application_id = vr_application_id AND i.instance_id = vr_form_instance_id;
	END IF;
	
	vr_message := NULL;
	
	vr_result := cn_p_set_node_creators(vr_application_id, vr_node_id, vr_contributors, 
										'Accepted', vr_creator_user_id, vr_creation_date);
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception(-1, 'ErrorInAddingNodeCreators');
		RETURN -1;
	END IF;
	
	IF vr_document_tree_node_id IS NOT NULL THEN
		vr_doc_ids := ARRAY(
			SELECT vr_node_id
		);
		
		vr_result := dct_p_add_tree_node_contents(vr_application_id, vr_document_tree_node_id, 
												  vr_doc_ids, NULL, vr_creator_user_id, vr_creation_date);
			
		IF vr_result <= 0 THEN
			CALL gfn_raise_exception(-1, 'ErrorInAddingTreeNodeContents');
			RETURN -1;
		END IF;
	END IF;
	
	SELECT vr_form_id = fw.form_id
	FROM fg_form_owners AS fw
	WHERE fw.application_id = vr_application_id AND 
		fw.owner_id = vr_node_type_id AND fw.deleted = FALSE AND vr_form_instance_id IS NULL
	LIMIT 1;
	
	IF vr_form_id IS NOT NULL THEN
		IF EXISTS(
			SELECT * 
			FROM cn_extensions AS ex
			WHERE ex.application_id = vr_application_id AND 
				ex.owner_id = vr_node_type_id AND ex.extension = 'Form' AND ex.deleted = FALSE
			LIMIT 1
		) THEN
			vr_instance_id := gen_random_uuid();
			
			DROP TABLE IF EXISTS inst_42394;
			
			CREATE TEMP TABLE inst_42394 OF form_instance_table_type;
			
			INSERT INTO inst_42394 (instance_id, form_id, owner_id, director_id, "admin")
			VALUES (vr_instance_id, vr_form_id, vr_node_id, NULL, NULL); 
			
			vr_instances := ARRAY(
				SELECT x
				FROM inst_42394 AS x
			);
			
			vr_result := fg_p_create_form_instance(vr_application_id, vr_instances, 
												   vr_creator_user_id, vr_creation_date);
				
			IF vr_result <= 0 THEN
				CALL gfn_raise_exception(-1, 'FormInstanceInitializationFailed');
				RETURN -1;
			END IF;
		ELSE
			vr_form_elements := ARRAY(
				SELECT Title::VARCHAR, ''::VARCHAR
				FROM fg_extended_form_elements AS e
				WHERE e.application_id = vr_application_id AND 
					e.form_id = vr_form_id AND e.deleted = FALSE
				ORDER BY e.sequence_number
			);
			
			vr_result := wk_p_create_wiki(vr_application_id, vr_node_id, vr_form_elements, 
										  TRUE, vr_creator_user_id, vr_creation_date);
			
			IF vr_result <= 0 THEN
				CALL gfn_raise_exception(-1, 'WikiInitializationFailed');
				RETURN -1;
			END IF;
		END IF;
	END IF;
	
	IF vr_workflow_id IS NOT NULL THEN
		SELECT 	vr_result = x.result,
				vr_message = x.error_message::VARCHAR
		FROM wf_p_start_new_workflow(vr_application_id, vr_node_id, vr_workflow_id, vr_wf_director_node_id, 
									 vr_wf_director_user_id, vr_creator_user_id, vr_creation_date);
		
		IF vr_result <= 0 THEN
			CALL gfn_raise_exception(-1, COALESCE(vr_message, 'WorkFlowInitializationFailed'));
			RETURN -1;
		END IF;
	END IF;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

