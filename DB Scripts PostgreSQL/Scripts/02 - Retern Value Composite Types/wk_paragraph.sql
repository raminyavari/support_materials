DROP TYPE IF EXISTS wk_paragraph_ret_composite;

CREATE TYPE wk_paragraph_ret_composite AS (
	paragraph_id			UUID,
	title_id				UUID,
	title					VARCHAR,
	body_text				VARCHAR,
	sequence_number			INTEGER,
	is_rich_text			BOOLEAN,
	creator_user_id			UUID,
	creation_date			TIMESTAMP,
	last_modification_date	TIMESTAMP,
	status					VARCHAR,
	total_count				INTEGER
);