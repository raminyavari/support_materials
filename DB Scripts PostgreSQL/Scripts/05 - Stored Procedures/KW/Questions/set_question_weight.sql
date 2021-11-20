DROP FUNCTION IF EXISTS kw_set_question_weight;

CREATE OR REPLACE FUNCTION kw_set_question_weight
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_weight			FLOAT
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_type_questions AS tq
	SET weight = CASE WHEN vr_weight <= 0 THEN NULL ELSE vr_weight END::FLOAT
	WHERE tq.application_id = vr_application_id AND tq.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

