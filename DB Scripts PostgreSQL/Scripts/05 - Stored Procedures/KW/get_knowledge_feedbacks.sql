DROP FUNCTION IF EXISTS kw_get_knowledge_feedbacks;

CREATE OR REPLACE FUNCTION kw_get_knowledge_feedbacks
(
	vr_application_id				UUID,
    vr_knowledge_id					UUID,
	vr_user_id						UUID,
	vr_feedback_type_id			 	INTEGER,
	vr_send_date_lower_threshold	TIMESTAMP,
	vr_send_date_upper_threshold	TIMESTAMP
)
RETURNS SETOF kw_feedback_ret_composite
AS
$$
DECLARE
	vr_ids	BIGINT[];
BEGIN
	vr_ids := ARRAY(
		SELECT fb.feedback_id
		FROM kw_feedbacks AS fb
			INNER JOIN users_normal AS usr
			ON usr.application_id = vr_application_id AND usr.user_id = fb.user_id
		WHERE fb.application_id = vr_application_id AND fb.knowledge_id = vr_knowledge_id AND 
			(vr_user_id IS NULL OR fb.user_id = vr_user_id) AND fb.deleted = FALSE AND
			(vr_feedback_type_id IS NULL OR fb.feedback_type_id = vr_feedback_type_id) AND
			(vr_send_date_lower_threshold IS NULL OR fb.send_date >= vr_send_date_lower_threshold) AND
			(vr_send_date_upper_threshold IS NULL OR fb.send_date < vr_send_date_upper_threshold)
	);

	RETURN QUERY
	SELECT *
	FROM kw_p_get_feedbacks_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

