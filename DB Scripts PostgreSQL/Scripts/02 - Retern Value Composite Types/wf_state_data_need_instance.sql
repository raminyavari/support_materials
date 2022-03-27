DROP TYPE IF EXISTS wf_state_data_need_instance_ret_composite;

CREATE TYPE wf_state_data_need_instance_ret_composite AS (
	instance_id		UUID,
	history_id		UUID,
	node_id			UUID,
	node_name		VARCHAR,
	node_type_id	UUID,
	filled			BOOLEAN,
	filling_date	TIMESTAMP,
	attachment_id	UUID,
	total_count		INTEGER
);