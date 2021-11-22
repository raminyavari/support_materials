DROP FUNCTION IF EXISTS kw_p_get_feedbacks_by_ids;

CREATE OR REPLACE FUNCTION kw_p_get_feedbacks_by_ids
(
	vr_application_id	UUID,
    vr_feedback_ids		BIGINT[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF kw_feedback_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT fb.feedback_id,
		   fb.knowledge_id,
		   fb.feedback_type_id,
		   fb.send_date,
		   fb.value,
		   fb.description,
		   usr.user_id,
		   usr.username,
		   usr.first_name,
		   usr.last_name,
		   vr_total_count
	FROM UNNEST(vr_feedback_ids) AS ex  
		INNER JOIN kw_feedbacks AS fb
		ON fb.application_id = vr_application_id AND fb.feedback_id = ex
		INNER JOIN users_normal AS usr
		ON usr.application_id = vr_application_id AND usr.user_id = fb.user_id
	ORDER BY fb.send_date DESC;
END;
$$ LANGUAGE plpgsql;

