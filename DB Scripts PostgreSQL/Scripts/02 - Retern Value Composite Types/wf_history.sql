DROP TYPE IF EXISTS wf_history_ret_composite;

CREATE TYPE wf_history_ret_composite AS (
	history_id				UUID,
	previous_history_id		UUID,
	owner_id				UUID,
	workflow_id				UUID,
	director_node_id		UUID,
	director_user_id		UUID,
	director_node_name		VARCHAR,
	director_node_type		VARCHAR,
	state_id				UUID,
	state_title				VARCHAR,
	selected_out_state_id	UUID,
	description				VARCHAR,
	sender_user_id			UUID,
	sender_username			VARCHAR,
	sender_first_name		VARCHAR,
	sender_last_name		VARCHAR,
	send_date				TIMESTAMP,
	poll_id					UUID,
	poll_name				VARCHAR,
	total_count				INTEGER
);