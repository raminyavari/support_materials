DROP TYPE IF EXISTS cn_node_type_ret_composite;

CREATE TYPE cn_node_type_ret_composite AS (
    node_type_id			UUID,
	parent_id				UUID,
	"name"					VARCHAR,
	additional_id			VARCHAR,
	additional_id_pattern	VARCHAR,
	archive					BOOLEAN,
	is_service				BOOLEAN,
	total_count				INTEGER
);