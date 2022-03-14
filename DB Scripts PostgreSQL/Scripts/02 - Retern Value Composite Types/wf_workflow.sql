DROP TYPE IF EXISTS wf_workflow_ret_composite;

CREATE TYPE wf_workflow_ret_composite AS (
	workflow_id	UUID,
	title		VARCHAR,
	description	VARCHAR,
	total_count	INTEGER
);