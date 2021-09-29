DROP TYPE IF EXISTS dct_file_ret_composite;

CREATE TYPE dct_file_ret_composite AS (
	owner_id	UUID,
	owner_type	VARCHAR,
	file_id		UUID,
	file_name	VARCHAR,
	"extension"	VARCHAR,
	mime		VARCHAR,
	"size"		INTEGER,
	total_count	INTEGER
);