DROP TYPE IF EXISTS wf_state_ret_composite;

CREATE TYPE wf_state_ret_composite AS (
	state_id	UUID,
	title		VARCHAR,
	total_count	INTEGER
);