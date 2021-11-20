DROP FUNCTION IF EXISTS kw_arithmetic_delete_question;

CREATE OR REPLACE FUNCTION kw_arithmetic_delete_question
(
	vr_application_id	UUID,
	vr_id				UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_type_questions AS tq
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tq.application_id = vr_application_id AND tq.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

