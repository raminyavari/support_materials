DROP FUNCTION IF EXISTS qa_remove_knowledgable_user;

CREATE OR REPLACE FUNCTION qa_remove_knowledgable_user
(
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_related_users AS r
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE r.application_id = vr_application_id AND 
		r.question_id = vr_question_id AND r.user_id = vr_user_id;
	
    -- remove dashboards
    IF vr_user_id IS NOT NULL THEN
		vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, vr_user_id, 
														 vr_question_id, NULL, 'Question', 'Knowledgable');
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::INTEGER;
		ELSE
			RETURN 1::INTEGER;
		END IF;
	END IF;
	-- end of remove dashboards
	
	RETURN 0::INTEGER;
END;
$$ LANGUAGE plpgsql;

