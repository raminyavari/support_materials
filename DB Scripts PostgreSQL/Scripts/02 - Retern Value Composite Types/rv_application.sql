DROP TYPE IF EXISTS rv_application_ret_composite;

CREATE TYPE rv_application_ret_composite AS (
    application_id		UUID,
	application_name	VARCHAR,
	title				VARCHAR,
	description			VARCHAR,
	creator_user_id		UUID,
	total_count			INTEGER
);