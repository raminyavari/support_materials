DROP FUNCTION IF EXISTS qa_get_questions_by_ids;

CREATE OR REPLACE FUNCTION qa_get_questions_by_ids
(
	vr_application_id	UUID,
    vr_question_ids		guid_table_type[],
    vr_current_user_id	UUID
)
RETURNS SETOF qa_question_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_question_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM qa_p_get_questions_by_ids(vr_application_id, vr_ids, vr_current_user_id) AS x;
END;
$$ LANGUAGE plpgsql;

