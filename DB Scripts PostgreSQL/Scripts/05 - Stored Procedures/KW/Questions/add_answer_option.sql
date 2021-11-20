DROP FUNCTION IF EXISTS kw_add_answer_option;

CREATE OR REPLACE FUNCTION kw_add_answer_option
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_type_question_id	UUID,
	vr_title			VARCHAR(2000),
	vr_value			FLOAT,
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_sequence_number 	INTEGER;
	vr_result			INTEGER;
BEGIN
	IF vr_value IS NULL OR vr_value < 0 OR vr_value > 10 OR EXISTS (
		SELECT 1
		FROM kw_answer_options AS ao
		WHERE ao.application_id = vr_application_id AND 
			ao.type_question_id = vr_type_question_id AND ao.deleted = FALSE AND ao.value = vr_value
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'AnswerOptionValueIsNotValid');
		RETURN -1::INTEGER;
	END IF;
	
	vr_sequence_number := COALESCE((
		SELECT MAX(SequenceNumber)
		FROM kw_answer_options AS ao
		WHERE ao.application_id = vr_application_id AND 
			ao.type_question_id = vr_type_question_id AND ao.deleted = FALSE
	), 0)::INTEGER + 1::INTEGER;
	
	INSERT INTO kw_answer_options (
		application_id,
		"id",
		type_question_id,
		title,
		"value",
		sequence_number,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_id,
		vr_type_question_id,
		vr_title,
		vr_value,
		vr_sequence_number,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

