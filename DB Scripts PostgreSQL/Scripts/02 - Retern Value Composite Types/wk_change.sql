DROP TYPE IF EXISTS wk_change_ret_composite;

CREATE TYPE wk_change_ret_composite AS (
	change_id				UUID,
	paragraph_id			UUID,
	title					VARCHAR,
	body_text				VARCHAR,
	status					VARCHAR,
	applied					BOOLEAN,
	send_date				TIMESTAMP,
	sender_user_id			UUID,
	sender_username			VARCHAR,
	sender_first_name		VARCHAR,
	sender_last_name		VARCHAR,
	total_count				INTEGER
);