DROP TYPE IF EXISTS dct_tree_ret_composite;

CREATE TYPE dct_tree_ret_composite AS (
	tree_id		UUID,
	"name"		VARCHAR,
	description	VARCHAR,
	is_template	BOOLEAN,
	total_count	INTEGER
);