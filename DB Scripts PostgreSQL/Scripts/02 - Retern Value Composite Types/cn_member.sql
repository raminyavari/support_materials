DROP TYPE IF EXISTS cn_member_ret_composite;

CREATE TYPE cn_member_ret_composite AS (
	node_id				UUID,
	user_id				UUID,
	membership_date		TIMESTAMP,
	is_admin			BOOLEAN,
	is_pending			BOOLEAN,
	status				VARCHAR,
	acception_date		TIMESTAMP,
	"position"			VARCHAR,
	
	node_additional_id	VARCHAR,
	node_name			VARCHAR,
	node_type_id		UUID,
	node_type			VARCHAR,
	
	username			VARCHAR,
	first_name			VARCHAR,
	last_name			VARCHAR,
	
	total_count			INTEGER
);