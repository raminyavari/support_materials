DROP TYPE IF EXISTS fg_poll_ret_composite;

CREATE TYPE fg_poll_ret_composite AS (
	poll_id				UUID, 
	is_copy_of_poll_id	UUID,
	owner_id			UUID,
	"name"				VARCHAR, 
	ref_name			VARCHAR,
	description			VARCHAR, 
	ref_description		VARCHAR, 
	begin_date			TIMESTAMP, 
	finish_date			TIMESTAMP,
	show_summary		BOOLEAN,
	hide_contributors	BOOLEAN,
	total_count			INTEGER
);