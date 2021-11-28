DROP FUNCTION IF EXISTS qa_get_existing_question_ids;

CREATE OR REPLACE FUNCTION qa_get_existing_question_ids
(
	vr_application_id	UUID,
    vr_question_ids		guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
    SELECT q.question_id AS "id"
	FROM UNNEST(vr_question_ids) AS x
		INNER JOIN qa_questions AS q
		ON q.question_id = x.value
	WHERE q.application_id = vr_application_id AND q.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

