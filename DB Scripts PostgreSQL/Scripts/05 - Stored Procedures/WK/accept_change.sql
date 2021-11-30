DROP FUNCTION IF EXISTS wk_accept_change;

CREATE OR REPLACE FUNCTION wk_accept_change
(
	vr_application_id		UUID,
    vr_change_id			UUID,
	vr_evaluator_user_id	UUID,
	vr_evaluation_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN wk_p_accept_change(vr_application_id, vr_change_id, 
							  vr_evaluator_user_id, vr_evaluation_date);
END;
$$ LANGUAGE plpgsql;

