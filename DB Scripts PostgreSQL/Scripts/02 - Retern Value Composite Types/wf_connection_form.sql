DROP TYPE IF EXISTS wf_connection_form_ret_composite;

CREATE TYPE wf_connection_form_ret_composite AS (
	workflow_id		UUID,
	in_state_id		UUID,
	out_state_id	UUID,
	form_id			UUID,
	form_title		VARCHAR,
	description		VARCHAR,
	necessary		BOOLEAN,
	total_count		INTEGER
);