DROP TYPE IF EXISTS fg_form_instance_ret_composite;

CREATE TYPE fg_form_instance_ret_composite AS (
	instance_id			UUID,
	form_id				UUID,
	owner_id			UUID,
	director_id			UUID,
	filled				BOOLEAN,
	filling_date		TIMESTAMP,
	form_title			VARCHAR,
	description			VARCHAR,
	creator_user_id		UUID,
	creator_username	VARCHAR,
	creator_first_name	VARCHAR,
	creator_last_name	VARCHAR,
	total_count			INTEGER
);