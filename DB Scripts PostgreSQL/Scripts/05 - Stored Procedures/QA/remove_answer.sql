DROP FUNCTION IF EXISTS qa_remove_answer;

CREATE OR REPLACE FUNCTION qa_remove_answer
(
	vr_application_id	UUID,
    vr_answer_id 		UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_answers AS ans
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE ans.application_id = vr_application_id AND ans.answer_id = vr_answer_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

