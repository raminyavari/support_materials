DROP TYPE IF EXISTS evt_event_ret_composite;

CREATE TYPE evt_event_ret_composite AS (
	event_id		UUID,
	event_type		VARCHAR,
	title			VARCHAR,
	description		VARCHAR,
	begin_date		TIMESTAMP,
	finish_date		TIMESTAMP,
	creator_user_id	UUID,
	total_count		INTEGER
);