DROP TYPE IF EXISTS wf_auto_message_ret_composite;

CREATE TYPE wf_auto_message_ret_composite AS (
	auto_message_id	UUID,
	owner_id		UUID,
	body_text		VARCHAR,
	audience_type	VARCHAR,
	ref_state_id	UUID,
	ref_state_title	VARCHAR,
	node_id			UUID,
	node_name		VARCHAR,
	node_type_id	UUID,
	node_type		VARCHAR,
	"admin"			BOOLEAN,
	total_count		INTEGER
);