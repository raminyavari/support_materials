DROP FUNCTION IF EXISTS kw_p_initialize_services;

CREATE OR REPLACE FUNCTION kw_p_initialize_services
(
	vr_application_id		UUID,
	vr_experience_type_id	UUID,
	vr_skill_type_id		UUID,
	vr_document_type_id		UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	IF EXISTS (
		SELECT 1
		FROM kw_knowledge_types AS kt
			INNER JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = kt.knowledge_type_id
		WHERE kt.application_id = vr_application_id
		LIMIT 1
	) THEN
		RETURN 1::INTEGER;
	END IF;
	
	INSERT INTO cn_services (
		application_id, 
		node_type_id, 
		service_title,
		enable_contribution, 
		admin_type, 
		max_acceptable_admin_level, 
		editable_for_admin,
		editable_for_creator, 
		editable_for_owners, 
		editable_for_experts, 
		editable_for_members,
		deleted, 
		is_document, 
		is_knowledge, 
		edit_suggestion, 
		is_tree, 
		sequence_number
	)
	SELECT	vr_application_id,
			x.type_id,
			x.type_name,
			x.contrib,
			'AreaAdmin',
			2::INTEGER, 
			TRUE, 
			TRUE, 
			TRUE, 
			FALSE, 
			FALSE, 
			FALSE,
			x.is_doc,
			TRUE,
			TRUE,
			FALSE,
			0::INTEGER
	FROM (
			SELECT	vr_experience_type_id AS type_id,
					'ثبت تجربه' AS type_name,
					TRUE AS contrib,
					FALSE AS is_doc
		
			UNION ALL
		
			SELECT	vr_skill_type_id AS type_id,
					'ثبت مهارت' AS type_name,
					FALSE AS contrib,
					FALSE AS is_doc
		
			UNION ALL
		
			SELECT	vr_document_type_id AS type_id,
					'ثبت مستند' AS type_name,
					TRUE AS contrib,
					TRUE AS is_doc
		) AS x;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

