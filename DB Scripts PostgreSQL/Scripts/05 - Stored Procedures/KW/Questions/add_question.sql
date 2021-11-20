DROP FUNCTION IF EXISTS kw_add_question;

CREATE OR REPLACE FUNCTION kw_add_question
(
	vr_application_id		UUID,
	vr_id					UUID,
	vr_knowledge_type_id	UUID,
	vr_node_id				UUID,
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
		WHERE q.application_id = vr_application_id AND q.title = vr_question_body
		LIMIT 1
	);
	
	IF vr_question_id IS NOT NULL AND EXISTS (
		SELECT 1
		FROM kw_type_questions AS tq
		WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id AND
			tq.question_id = vr_question_id AND tq.deleted = FALSE
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'QuestionAlreadyExists');
		RETURN -1::INTEGER;
	END IF;
	
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
	
	vr_sequence_number := COALESCE((
		SELECT MAX(tq.sequence_number)
		FROM kw_type_questions AS tq
		WHERE tq.application_id = vr_application_id AND tq.knowledge_type_id = vr_knowledge_type_id
	), 0)::INTEGER + 1::INTEGER;
	
	INSERT INTO kw_type_questions (
		application_id,
		"id",
		knowledge_type_id,
		question_id,
		node_id,
		sequence_number,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_id,
		vr_knowledge_type_id,
		vr_question_id,
		vr_node_id,
		vr_sequence_number,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

