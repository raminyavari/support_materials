DROP TYPE IF EXISTS qa_answer_ret_composite;

CREATE TYPE qa_answer_ret_composite AS (
	answer_id			UUID,
	question_id			UUID,
	answer_body			VARCHAR,
	sender_user_id		UUID,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR,
	send_date			TIMESTAMP,
	likes_count			INTEGER,
	dislikes_count		INTEGER,
	like_status			BOOLEAN,
	total_count			INTEGER
);