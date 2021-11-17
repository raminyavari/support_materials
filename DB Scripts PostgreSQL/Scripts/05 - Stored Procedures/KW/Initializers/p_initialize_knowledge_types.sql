DROP FUNCTION IF EXISTS kw_p_initialize_knowledge_types;

CREATE OR REPLACE FUNCTION kw_p_initialize_knowledge_types
(
	vr_application_id		UUID,
	vr_admin_id				UUID,
	vr_experience_type_id	UUID,
	vr_skill_type_id		UUID,
	vr_document_type_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_now	TIMESTAMP;
BEGIN
	vr_now := NOW();
	
	IF NOT EXISTS (
		SELECT 1
		FROM kw_knowledge_types AS kt
		WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_experience_type_id
		LIMIT 1
	) THEN
		INSERT INTO kw_knowledge_types (
			application_id, 
			knowledge_type_id,
			evaluation_type, 
			evaluators, 
			searchable_after, 
			score_scale, 
			min_acceptable_score,
			node_select_type, 
			creator_user_id, 
			creation_date, 
			deleted
		)
		VALUES (
			vr_application_id, 
			vr_experience_type_id, 
			'EN', 
			'Experts',
			'Evaluation', 
			10::INTEGER, 
			5::FLOAT, 
			'Free', 
			vr_admin_id, 
			vr_now, 
			FALSE
		);
	END IF;
	
	IF NOT EXISTS (
		SELECT 1
		FROM kw_knowledge_types AS kt
		WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_skill_type_id
		LIMIT 1
	) THEN
		INSERT INTO kw_knowledge_types (
			application_id, 
			knowledge_type_id,
			evaluation_type, 
			evaluators, 
			searchable_after, 
			score_scale, 
			min_acceptable_score,
			node_select_type, 
			creator_user_id, 
			creation_date, 
			deleted
		)
		VALUES (
			vr_application_id, 
			vr_skill_type_id, 
			'EN', 
			'Experts',
			'Evaluation', 
			10::INTEGER, 
			5::FLOAT, 
			'Free', 
			vr_admin_id, 
			vr_now, 
			FALSE
		);
	END IF;
	
	IF NOT EXISTS (
		SELECT 1
		FROM kw_knowledge_types AS kt
		WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_document_type_id
		LIMIT 1
	) THEN
		INSERT INTO kw_knowledge_types (
			application_id, 
			knowledge_type_id,
			evaluation_type, 
			evaluators, 
			searchable_after, 
			score_scale, 
			min_acceptable_score,
			node_select_type, 
			creator_user_id, 
			creation_date, 
			deleted
		)
		VALUES (
			vr_application_id, 
			vr_document_type_id, 
			'EN', 
			'Experts',
			'Evaluation', 
			10::INTEGER, 
			5::FLOAT, 
			'Free', 
			vr_admin_id, 
			vr_now, 
			FALSE
		);
	END IF;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

