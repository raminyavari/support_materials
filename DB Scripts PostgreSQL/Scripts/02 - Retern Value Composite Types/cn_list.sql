DROP TYPE IF EXISTS cn_list_ret_composite;

CREATE TYPE cn_list_ret_composite AS (
	list_id			UUID,
	list_name		VARCHAR,
	description		VARCHAR,
	additional_id	VARCHAR,
	node_type_id	UUID,
	node_type		VARCHAR,
	owner_id		UUID,
	owner_type		VARCHAR,
	total_count		BIGINT
);