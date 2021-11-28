DROP FUNCTION IF EXISTS qa_get_related_expert_and_member_ids;

CREATE OR REPLACE FUNCTION qa_get_related_expert_and_member_ids
(
	vr_application_id	UUID,
	vr_question_id	 	UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT DISTINCT x.id
	FROM (
			SELECT nm.user_id AS "id"
			FROM qa_related_nodes AS rn
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND 
					nm.node_id = rn.node_id AND nm.is_pending = FALSE
			WHERE rn.application_id = vr_application_id AND rn.question_id = vr_question_id
			
			UNION ALL
			
			SELECT ex.user_id AS "id"
			FROM qa_related_nodes AS rn
				INNER JOIN cn_view_experts AS ex
				ON ex.application_id = vr_application_id AND ex.node_id = rn.node_id
			WHERE rn.application_id = vr_application_id AND rn.question_id = vr_question_id
		) AS x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.user_id = x.id AND un.is_approved = TRUE;
END;
$$ LANGUAGE plpgsql;

