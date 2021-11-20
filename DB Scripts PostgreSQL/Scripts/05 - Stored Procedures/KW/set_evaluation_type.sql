DROP FUNCTION IF EXISTS kw_set_evaluation_type;

CREATE OR REPLACE FUNCTION kw_set_evaluation_type
(
	vr_application_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_evaluation_type		VARCHAR(20)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_knowledge_types AS kt
	SET evaluation_type = vr_evaluation_type
	WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_knowledge_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

