DROP TYPE IF EXISTS fg_form_instance_element_ret_composite;

CREATE TYPE fg_form_instance_element_ret_composite AS (
	element_id			UUID,
	instance_id			UUID,
	ref_element_id		UUID,
	title				VARCHAR,
	"name"				VARCHAR,
	help				VARCHAR,
	sequence_number		INTEGER,
	"type"				VARCHAR,
	"info"				VARCHAR,
	weight				FLOAT,
	text_value			VARCHAR,
	float_value			FLOAT,
	bit_value			BOOLEAN,
	date_value			TIMESTAMP,
	filled				BOOLEAN,
	necessary			BOOLEAN,
	unique_value		BOOLEAN,
	editions_count		INTEGER,
	creator_user_id		UUID,
	creator_username	VARCHAR,
	creator_first_name	VARCHAR,
	creator_last_name	VARCHAR
);