DROP FUNCTION IF EXISTS kw_set_evaluators;

CREATE OR REPLACE FUNCTION kw_set_evaluators
(
	vr_application_id			UUID,
	vr_knowledge_type_id		UUID,
	vr_evaluators				VARCHAR(20),
	vr_min_evaluations_count 	INTEGER
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_knowledge_types AS kt
	SET evaluators = vr_evaluators,
		min_evaluations_count = vr_min_evaluations_count
	WHERE kt.application_id = vr_application_id AND kt.knowledge_type_id = vr_knowledge_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

