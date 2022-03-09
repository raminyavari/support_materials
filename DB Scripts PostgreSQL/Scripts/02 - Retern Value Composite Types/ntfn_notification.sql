DROP TYPE IF EXISTS ntfn_notification_ret_composite;

CREATE TYPE ntfn_notification_ret_composite AS (
	"id"				BIGINT,
	notification_id		UUID,
	user_id				UUID,
	subject_id			UUID,
	ref_item_id			UUID,
	subject_name		VARCHAR,
	subject_type		VARCHAR,
	sender_user_id		UUID,
	sender_username		VARCHAR,
	sender_first_name	VARCHAR,
	sender_last_name	VARCHAR,
	send_date			TIMESTAMP,
	"action"			VARCHAR,
	description			VARCHAR,
	"info"				VARCHAR,
	user_status			VARCHAR,
	seen				BOOLEAN,
	view_date			TIMESTAMP,
	total_count			BIGINT
);