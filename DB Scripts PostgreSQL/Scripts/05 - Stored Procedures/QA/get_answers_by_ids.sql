DROP FUNCTION IF EXISTS qa_get_answers_by_ids;

CREATE OR REPLACE FUNCTION qa_get_answers_by_ids
(
	vr_application_id	UUID,
	vr_answer_ids 		guid_table_type[],
	vr_current_user_id	UUID
)
RETURNS SETOF qa_answer_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_answer_ids) AS x
	);
	
	RETURN QUERY
	SELECT *
	FROM qa_p_get_answers_by_ids(vr_application_id, vr_ids, vr_current_user_id);
END;
$$ LANGUAGE plpgsql;

