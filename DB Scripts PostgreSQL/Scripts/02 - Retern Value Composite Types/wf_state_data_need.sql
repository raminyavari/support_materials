DROP TYPE IF EXISTS wf_state_data_need_ret_composite;

CREATE TYPE wf_state_data_need_ret_composite AS (
	"id"			UUID,
	state_id		UUID,
	workflow_id		UUID,
	node_type_id	UUID,
	form_id			UUID,
	form_title		VARCHAR,
	description		VARCHAR,
	node_type		VARCHAR,
	multi_select	BOOLEAN,
	"admin"			BOOLEAN,
	necessary		BOOLEAN,
	total_count		INTEGER
);