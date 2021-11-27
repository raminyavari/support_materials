DROP FUNCTION IF EXISTS qa_is_related_expert_or_member;

CREATE OR REPLACE FUNCTION qa_is_related_expert_or_member
(
	vr_application_id	UUID,
    vr_question_id		UUID,
	vr_user_id			UUID,
	vr_experts		 	BOOLEAN,
	vr_members		 	BOOLEAN,
	vr_check_candidates	BOOLEAN
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_exists	BOOLEAN DEFAULT FALSE;
BEGIN
	vr_experts := COALESCE(vr_experts, FALSE)::BOOLEAN;
	vr_members := COALESCE(vr_members, FALSE)::BOOLEAN;
	vr_check_candidates := COALESCE(vr_check_candidates, FALSE)::BOOLEAN;

	IF vr_exists = FALSE AND vr_experts = TRUE AND vr_check_candidates = TRUE THEN
		SELECT vr_exists = TRUE
		FROM qa_questions AS q
			INNER JOIN qa_related_nodes AS rn
			ON q.application_id = vr_application_id AND rn.question_id = q.question_id
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
			INNER JOIN qa_candidate_relations AS cr
			ON cr.application_id = vr_application_id AND 
				(cr.node_id = nd.node_id OR cr.node_type_id = nd.node_type_id) AND cr.deleted = FALSE
			INNER JOIN cn_view_node_members AS nm
			ON nm.application_id = vr_application_id AND 
				nm.node_id = rn.node_id AND nm.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND q.question_id = vr_question_id
		LIMIT 1;
	END IF;

	IF vr_exists = FALSE AND vr_members = TRUE AND vr_check_candidates = TRUE THEN
		SELECT vr_exists = TRUE
		FROM qa_questions AS q
			INNER JOIN qa_related_nodes AS rn
			ON q.application_id = vr_application_id AND rn.question_id = q.question_id
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
			INNER JOIN qa_candidate_relations AS cr
			ON cr.application_id = vr_application_id AND 
				(cr.node_id = nd.node_id OR cr.node_type_id = nd.node_type_id) AND cr.deleted = FALSE
			INNER JOIN cn_view_experts AS ex
			ON ex.application_id = vr_application_id AND 
				ex.node_id = rn.node_id AND ex.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND q.question_id = vr_question_id
		LIMIT 1;
	END IF;

	IF vr_exists = FALSE AND vr_experts = TRUE AND vr_check_candidates = FALSE THEN
		SELECT vr_exists = TRUE
		FROM qa_related_nodes AS rn
			INNER JOIN cn_view_experts AS ex
			ON ex.application_id = vr_application_id AND 
				ex.node_id = rn.node_id AND ex.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND rn.question_id = vr_question_id
		LIMIT 1;
	END IF;

	IF vr_exists = FALSE AND vr_members = TRUE AND vr_check_candidates = FALSE THEN
		SELECT vr_exists = TRUE
		FROM qa_related_nodes AS rn
			INNER JOIN cn_view_node_members AS nm
			ON nm.application_id = vr_application_id AND 
				nm.node_id = rn.node_id AND nm.user_id = vr_user_id
		WHERE rn.application_id = vr_application_id AND rn.question_id = vr_question_id
		LIMIT 1;
	END IF;

	RETURN vr_exists;
END;
$$ LANGUAGE plpgsql;

