DROP FUNCTION IF EXISTS kw_modify_answer_option;

CREATE OR REPLACE FUNCTION kw_modify_answer_option
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_title			VARCHAR(2000),
	vr_value			FLOAT,
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_type_question_id	UUID;
	vr_sequence_number 	INTEGER;
	vr_result			INTEGER;
BEGIN
	vr_type_question_id := (
		SELECT ao.type_question_id
		FROM kw_answer_options AS ao
		WHERE ao.application_id = vr_application_id AND ao.id = vr_id
		LIMIT 1
	);

	IF vr_value IS NULL OR vr_value < 0 OR vr_value > 10 OR EXISTS (
		SELECT 1
		FROM kw_answer_options AS ao
		WHERE ao.application_id = vr_application_id AND ao.type_question_id = vr_type_question_id AND 
			ao.deleted = FALSE AND ao.value <> vr_id AND ao.value = vr_value
		LIMIT 1
	) THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'AnswerOptionValueIsNotValid');
		RETURN -1::INTEGER;
	END IF;
	
	UPDATE kw_answer_options AS ao
	SET title = vr_title,
		"value" = vr_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE ao.application_id = vr_application_id AND ao.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

