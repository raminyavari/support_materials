DROP TYPE IF EXISTS wk_title_ret_composite;

CREATE TYPE wk_title_ret_composite AS (
	title_id				UUID,
	owner_id				UUID,
	title					VARCHAR,
	sequence_number			INTEGER,
	creator_user_id			UUID,
	creation_date			TIMESTAMP,
	last_modification_date	TIMESTAMP,
	status					VARCHAR,
	total_count				INTEGER
);