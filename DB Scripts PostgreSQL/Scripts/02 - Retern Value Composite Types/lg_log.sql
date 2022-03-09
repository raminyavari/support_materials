DROP TYPE IF EXISTS lg_log_ret_composite;

CREATE TYPE lg_log_ret_composite AS (
	log_id				BIGINT,
	user_id				UUID,
	username			VARCHAR,
	first_name			VARCHAR,
	last_name			VARCHAR,
	host_address		VARCHAR,
	host_name			VARCHAR,
	"action"			VARCHAR,
	date				TIMESTAMP,
	"info"				VARCHAR,
	module_identifier	VARCHAR,
	total_count			BIGINT
);
