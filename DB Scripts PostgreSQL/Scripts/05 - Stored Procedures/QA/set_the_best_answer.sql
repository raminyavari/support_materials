DROP FUNCTION IF EXISTS qa_set_the_best_answer;

CREATE OR REPLACE FUNCTION qa_set_the_best_answer
(
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_answer_id		UUID,
    vr_publish	 		BOOLEAN,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_questions AS q
	SET best_answer_id = vr_answer_id,
		publication_date = CASE WHEN vr_publish = TRUE
			THEN COALESCE(q.publication_date, vr_now) ELSE q.publication_date END,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE vr_answer_id IS NOT NULL AND 
		q.application_id = vr_application_id AND q.question_id = vr_question_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	-- remove dashboards
	IF vr_publish = TRUE THEN
		vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, 
														 vr_question_id, NULL, 'Question', NULL);
			
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::INTEGER;
		END IF;
	END IF;
	-- end of remove dashboards
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

