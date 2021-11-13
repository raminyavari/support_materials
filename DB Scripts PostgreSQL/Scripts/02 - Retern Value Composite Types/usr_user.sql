DROP TYPE IF EXISTS usr_user_ret_composite;

CREATE TYPE usr_user_ret_composite AS (
	user_id			UUID, 
	username		VARCHAR,
	first_name		VARCHAR, 
	last_name		VARCHAR, 
	birthdate		TIMESTAMP,
	about_me		VARCHAR,
	city			VARCHAR,
	organization	VARCHAR,
	department		VARCHAR,
	job_title		VARCHAR,
	main_phone_id	UUID,
	main_email_id	UUID,
	is_approved		BOOLEAN, 
	is_locked_out	BOOLEAN,
	total_count		BIGINT
);