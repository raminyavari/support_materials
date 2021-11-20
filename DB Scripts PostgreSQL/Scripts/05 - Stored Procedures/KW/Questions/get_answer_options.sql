DROP FUNCTION IF EXISTS kw_get_answer_options;

CREATE OR REPLACE FUNCTION kw_get_answer_options
(
	vr_application_id		UUID,
	vr_type_question_ids	guid_table_type[]
)
RETURNS TABLE (
	"id"				UUID, 
	type_question_id	UUID, 
	title				VARCHAR,
	"value"				FLOAT
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	ao.id,
			ao.type_question_id, 
			ao.title,
			ao.value
	FROM UNNEST(vr_type_question_ids) AS x
		INNER JOIN kw_type_questions AS tq
		ON tq.application_id = vr_application_id AND tq.id = x.value
		INNER JOIN kw_answer_options AS ao
		ON ao.application_id = vr_application_id AND ao.type_question_id = tq.id
	WHERE tq.deleted = FALSE AND ao.deleted = FALSE
	ORDER BY ao.type_question_id ASC, ao.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;

