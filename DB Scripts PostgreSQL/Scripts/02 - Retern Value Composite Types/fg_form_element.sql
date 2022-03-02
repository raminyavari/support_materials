DROP TYPE IF EXISTS fg_form_element_ret_composite;

CREATE TYPE fg_form_element_ret_composite AS (
	element_id		UUID,
	form_id			UUID,
	title			VARCHAR,
	"name"			VARCHAR,
	help			VARCHAR,
	necessary		BOOLEAN,
	unique_value	BOOLEAN,
	sequence_number	INTEGER,
	"type"			VARCHAR,
	"info"			VARCHAR,
	weight			FLOAT,
	total_count		INTEGER
);