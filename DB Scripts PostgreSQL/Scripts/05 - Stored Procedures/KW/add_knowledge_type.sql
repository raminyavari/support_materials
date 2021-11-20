DROP FUNCTION IF EXISTS kw_add_knowledge_type;

CREATE OR REPLACE FUNCTION kw_add_knowledge_type
(
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_current_user_id		UUID,
	vr_now	 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE((
		SELECT 1
		FROM cn_services AS s
		WHERE s.application_id = vr_application_id AND 
			s.node_type_id = vr_knowledge_type_id AND COALESCE(s.is_knowledge, FALSE) = TRUE
		LIMIT 1
	), 0) = 0 THEN
		EXECUTE gfn_raise_exception(-1::ITNEGER);
		RETURN -1;
	END IF;
	
	IF EXISTS(
		SELECT 1 
		FROM kw_knowledge_types AS kt
		WHERE kt.knowledge_type_id = vr_knowledge_type_id
		LIMIT 1
	) THEN
		UPDATE kw_knowledge_types AS kt
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_knowledge_type_id;
	ELSE
		INSERT INTO kw_knowledge_types (
			application_id,
			knowledge_type_id,
			creator_user_id,
			creation_date,
			convert_evaluators_to_experts,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_knowledge_type_id,
			vr_current_user_id,
			vr_now,
			FALSE,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

