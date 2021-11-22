DROP FUNCTION IF EXISTS kw_get_feedback_status;

CREATE OR REPLACE FUNCTION kw_get_feedback_status
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID,
	vr_user_id			UUID
)
RETURNS TABLE (
	total_financial_feedbacks	FLOAT,
	total_temporal_feedbacks	FLOAT,
	financial_feedback_status	FLOAT,
	temporal_feedback_status	FLOAT
)
AS
$$
BEGIN
	SELECT
		SUM(CASE WHEN fb.feedback_type_id = 1 THEN fb.value ELSE 0 END)::FLOAT AS total_financial_feedbacks,
		SUM(CASE WHEN fb.feedback_type_id = 2 THEN fb.value ELSE 0 END)::FLOAT AS total_temporal_feedbacks,
		SUM(CASE WHEN fb.user_id = vr_user_id AND fb.feedback_type_id = 1 THEN fb.value ELSE 0 END)::FLOAT AS financial_feedback_status,
		SUM(CASE WHEN fb.user_id = vr_user_id AND fb.feedback_type_id = 2 THEN fb.value ELSE 0 END)::FLOAT AS temporal_feedback_status
	FROM kw_feedbacks AS fb
	WHERE fb.application_id = vr_application_id AND 
		fb.knowledge_id = vr_knowledge_id AND fb.deleted = FALSE
	LIMIT 1;
END;
$$ LANGUAGE plpgsql;

