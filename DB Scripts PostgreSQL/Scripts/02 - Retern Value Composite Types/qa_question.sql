DROP TYPE IF EXISTS qa_question_ret_composite;

CREATE TYPE qa_question_ret_composite AS (
	question_id			UUID,
	workflow_id			UUID,
	title				VARCHAR,
	description			VARCHAR,
	send_date			TIMESTAMP,
	best_answer_id		UUID,
	sender_user_id		UUID,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR,
	status				VARCHAR,
	publication_date	TIMESTAMP,
	answers_count		INTEGER,
	likes_count			INTEGER,
	dislikes_count		INTEGER,
	like_status			BOOLEAN,
	follow_status		BOOLEAN,
	total_count			INTEGER
);