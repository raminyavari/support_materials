DROP TYPE IF EXISTS kw_feedback_ret_composite;

CREATE TYPE kw_feedback_ret_composite AS (
	feedback_id			BIGINT,
	knowledge_id		UUID,
	feedback_type_id	INTEGER,
	send_date			TIMESTAMP,
	"value"				FLOAT,
	description			VARCHAR,
	user_id				UUID,
	username			VARCHAR,
	first_name			VARCHAR,
	last_name			VARCHAR,
	total_count			INTEGER
);