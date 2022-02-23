DROP TYPE IF EXISTS fg_form_ret_composite;

CREATE TYPE fg_form_ret_composite AS (
	form_id		UUID,
	title		VARCHAR,
	"name"		VARCHAR,
	description	VARCHAR,
	total_count	INTEGER
);