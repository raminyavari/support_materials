DROP FUNCTION IF EXISTS kw_arithmetic_delete_feedback;

CREATE OR REPLACE FUNCTION kw_arithmetic_delete_feedback
(
	vr_application_id	UUID,
    vr_feedback_id		BIGINT
)
RETURNS BIGINT
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_feedbacks AS f
	SET deleted = TRUE
	WHERE f.application_id = vr_application_id AND f.feedback_id = vr_feedback_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

