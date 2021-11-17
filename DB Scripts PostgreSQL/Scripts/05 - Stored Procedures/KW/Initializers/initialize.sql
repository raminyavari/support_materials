DROP FUNCTION IF EXISTS kw_initialize;

CREATE OR REPLACE FUNCTION kw_initialize
(
	vr_application_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE 
	vr_experience_type_id	UUID;
	vr_skill_type_id		UUID;
	vr_document_type_id		UUID;
	vr_admin_id				UUID;
	vr_result				INTEGER;
BEGIN
	 vr_experience_type_id := (
		SELECT ct.node_type_id
		FROM cn_node_types AS ct
		WHERE ct.application_id = vr_application_id AND ct.additional_id = '9'
		LIMIT 1
	);
	
	vr_skill_type_id := (
		SELECT ct.node_type_id
		FROM cn_node_types AS ct
		WHERE ct.application_id = vr_application_id AND ct.additional_id = '8'
		LIMIT 1
	);
	
	vr_document_type_id := (
		SELECT ct.node_type_id
		FROM cn_node_types AS ct
		WHERE ct.application_id = vr_application_id AND ct.additional_id = '10'
		LIMIT 1
	);
	
	vr_admin_id := (
		SELECT un.user_id 
		FROM users_normal AS un 
		WHERE un.application_id = vr_application_id AND un.username = 'admin'
		LIMIT 1
	);
	
	vr_result := kw_p_initialize_forms(vr_application_id, vr_admin_id, vr_experience_type_id, 
									   vr_skill_type_id, vr_document_type_id);
	
	vr_result := kw_p_initialize_knowledge_types(vr_application_id, vr_admin_id, vr_experience_type_id, 
												 vr_skill_type_id, vr_document_type_id);
	
	vr_result := kw_p_initialize_questions(vr_application_id, vr_admin_id, vr_experience_type_id, 
										   vr_skill_type_id, vr_document_type_id);
		
	vr_result := kw_p_initialize_services(vr_application_id, vr_experience_type_id, 
										  vr_skill_type_id, vr_document_type_id);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

