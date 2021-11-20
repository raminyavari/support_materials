DROP FUNCTION IF EXISTS kw_modify_question;

CREATE OR REPLACE FUNCTION kw_modify_question
(
	vr_application_id		UUID,
	vr_id					UUID,
	vr_question_body	 	VARCHAR(2000),
	vr_current_user_id		UUID,
	vr_now	 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_question_id		UUID;
	vr_sequence_number 	INTEGER;
BEGIN
	IF vr_question_body IS NOT NULL THEN 
		vr_question_body := gfn_verify_string(vr_question_body);
	END IF;
	
	vr_question_id := (
		SELECT q.question_id
		FROM kw_questions AS q
		WHERE q.application_id = vr_application_id AND q.title = vr_question_body AND q.deleted = FALSE
		LIMIT 1
	);
	
	IF vr_question_id IS NULL THEN
		vr_question_id := gen_random_uuid();
		
		INSERT INTO kw_questions (
			application_id,
			question_id,
			title,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_question_id,
			vr_question_body,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	UPDATE kw_type_questions AS tq
	SET question_id = vr_question_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tq.application_id = vr_application_id AND tq.id = vr_id;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

