DROP TYPE IF EXISTS dct_tree_node_ret_composite;

CREATE TYPE dct_tree_node_ret_composite AS (
	tree_node_id	UUID,
	tree_id			UUID,
	parent_node_id	UUID,
	"name"			VARCHAR,
	has_child		BOOLEAN,
	total_count		INTEGER
);