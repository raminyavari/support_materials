DROP TYPE IF EXISTS sh_post_ret_composite;

CREATE TYPE sh_post_ret_composite AS (
	post_id					UUID,
	ref_post_id				UUID,
	post_type_id			INTEGER,
	description				VARCHAR,
	original_description 	VARCHAR,
	shared_object_id		UUID,
	sender_user_id			UUID,
	send_date				TIMESTAMP,
	first_name				VARCHAR,
	last_name				VARCHAR,
	job_title				VARCHAR,
	original_sender_user_id	UUID,
	original_send_date		TIMESTAMP,
	original_first_name		VARCHAR,
	original_last_name		VARCHAR,
	original_job_title		VARCHAR,
	last_modification_date	TIMESTAMP,
	owner_id				UUID,
	owner_type				VARCHAR,
	privacy					VARCHAR,
	has_picture				BOOLEAN,
	comments_count			INTEGER,
	likes_count				INTEGER,
	dislikes_count			INTEGER,
	like_status				INTEGER
);