DROP TYPE IF EXISTS kw_history_ret_composite;

CREATE TYPE kw_history_ret_composite AS (
	"id"				BIGINT,
	knowledge_id		UUID,
	"action"			VARCHAR,
	text_options		VARCHAR,
	description			VARCHAR,
	actor_user_id		UUID,
	actor_username		VARCHAR,
	actor_first_name	VARCHAR,
	actor_last_name		VARCHAR,
	deputy_user_id		UUID,
	deputy_username		VARCHAR,
	deputy_first_name	VARCHAR,
	deputy_last_name	VARCHAR,
	action_date			TIMESTAMP,
	reply_to_history_id	BIGINT,
	wf_version_id		INTEGER,
	is_creator			BOOLEAN,
	is_contributor		BOOLEAN,
	total_count			BIGINT
);