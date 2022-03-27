DROP TYPE IF EXISTS wf_connection_ret_composite;

CREATE TYPE wf_connection_ret_composite AS (
	"id"					UUID,
	workflow_id				UUID,
	in_state_id				UUID,
	out_state_id			UUID,
	sequence_number			INTEGER,
	connection_label		VARCHAR,
	attachment_required		BOOLEAN,
	attachment_title		VARCHAR,
	node_required			BOOLEAN,
	node_type_id			UUID,
	node_type				VARCHAR,
	node_type_description	VARCHAR,
	total_count				INTEGER
);