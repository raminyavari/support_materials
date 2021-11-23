DROP FUNCTION IF EXISTS qa_p_get_workflows_by_ids;

CREATE OR REPLACE FUNCTION qa_p_get_workflows_by_ids
(
	vr_application_id	UUID,
    vr_workflow_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF qa_workflow_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT	w.workflow_id,
			w.name,
			w.description,
			w.initial_check_needed,
			w.final_confirmation_needed,
			w.action_deadline,
			w.answer_by,
			w.publish_after,
			w.removable_after_confirmation,
			w.node_select_type,
			w.disable_comments,
			w.disable_question_likes,
			w.disable_answer_likes,
			w.disable_comment_likes,
			w.disable_best_answer,
			vr_total_count
	FROM UNNEST(vr_workflow_ids) WITH ORDINALITY AS i("id", seq)
		INNER JOIN qa_workflows AS w
		ON w.application_id = vr_application_id AND w.workflow_id = i.id
	ORDER BY i.seq ASC;
END;
$$ LANGUAGE plpgsql;

