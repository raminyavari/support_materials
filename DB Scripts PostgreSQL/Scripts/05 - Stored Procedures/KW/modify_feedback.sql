DROP FUNCTION IF EXISTS kw_modify_feedback;

CREATE OR REPLACE FUNCTION kw_modify_feedback
(
	vr_application_id	UUID,
    vr_feedback_id		BIGINT,
	vr_value			FLOAT,
	vr_description 		VARCHAR(2000)
)
RETURNS BIGINT
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_feedbacks AS f
	SET "value" = vr_value,
		description = gfn_verify_string(vr_description)
	WHERE f.application_id = vr_application_id AND f.feedback_id = vr_feedback_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

