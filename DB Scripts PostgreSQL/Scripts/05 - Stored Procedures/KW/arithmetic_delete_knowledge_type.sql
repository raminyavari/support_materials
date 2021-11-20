DROP FUNCTION IF EXISTS kw_arithmetic_delete_knowledge_type;

CREATE OR REPLACE FUNCTION kw_arithmetic_delete_knowledge_type
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
	UPDATE kw_knowledge_types AS kt
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_knowledge_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

