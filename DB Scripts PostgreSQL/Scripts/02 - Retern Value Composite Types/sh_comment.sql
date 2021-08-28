DROP TYPE IF EXISTS sh_comment_ret_composite;

CREATE TYPE sh_comment_ret_composite AS (
    comment_id		UUID,
	post_id			UUID,
	description		VARCHAR,
	sender_user_id	UUID,
	send_date		TIMESTAMP,
	first_name		VARCHAR,
	last_name		VARCHAR,
	likes_count		INTEGER,
	dislikes_count	INTEGER,
	like_status		BOOLEAN
);