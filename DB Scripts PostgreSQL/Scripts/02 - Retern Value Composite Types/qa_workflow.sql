DROP TYPE IF EXISTS qa_workflow_ret_composite;

CREATE TYPE qa_workflow_ret_composite AS (
	workflow_id						UUID,
	"name"							VARCHAR,
	description						VARCHAR,
	initial_check_needed			BOOLEAN,
	final_confirmation_needed		BOOLEAN,
	action_deadline					INTEGER,
	answer_by						VARCHAR,
	publish_after					VARCHAR,
	removable_after_confirmation	BOOLEAN,
	node_select_type				VARCHAR,
	disable_comments				BOOLEAN,
	disable_question_likes			BOOLEAN,
	disable_answer_likes			BOOLEAN,
	disable_comment_likes			BOOLEAN,
	disable_best_answer				BOOLEAN,
	total_count						INTEGER
);