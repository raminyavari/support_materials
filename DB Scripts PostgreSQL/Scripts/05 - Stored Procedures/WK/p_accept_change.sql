DROP FUNCTION IF EXISTS wk_p_accept_change;

CREATE OR REPLACE FUNCTION wk_p_accept_change
(
	vr_application_id		UUID,
    vr_change_id			UUID,
	vr_evaluator_user_id	UUID,
	vr_evaluation_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wk_changes AS ch
	SET status = 'Accepted',
		acception_date = vr_evaluation_date,
		evaluator_user_id = vr_evaluator_user_id,
		evaluation_date = vr_evaluation_date
	WHERE ch.application_id = vr_application_id AND ch.change_id = vr_change_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

