DROP FUNCTION IF EXISTS fg_get_poll_element_instances;

CREATE OR REPLACE FUNCTION fg_get_poll_element_instances
(
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_element_id		UUID,
	vr_count		 	INTEGER,
	vr_lower_boundary	INTEGER
)
RETURNS TABLE (
	"row_number"			INTEGER,
	user_id					UUID,
	username				VARCHAR,
	first_name				VARCHAR,
	last_name				VARCHAR,
	element_id				UUID,
	ref_element_id			UUID,
	"type"					VARCHAR,
	text_value				VARCHAR,
	float_value				FLOAT,
	bit_value				BOOLEAN,
	date_value				TIMESTAMP,
	creation_date			TIMESTAMP,
	last_modification_date	TIMESTAMP
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM (
			SELECT	ROW_NUMBER() OVER(ORDER BY 
									  COALESCE(ie.last_modification_date, ie.creation_date) DESC, 
									  ie.element_id DESC)::INTEGER AS "row_number",
					un.user_id,
					un.username,
					un.first_name,
					un.last_name,
					ie.element_id,
					ie.ref_element_id,
					ie.type,
					COALESCE(ie.text_value, '') AS text_value,
					ie.float_value,
					ie.bit_value,
					ie.date_value,
					ie.creation_date,
					ie.last_modification_date
			FROM fg_form_instances AS fi
				INNER JOIN fg_instance_elements AS ie
				ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND
					ie.ref_element_id = vr_element_id AND ie.deleted = FALSE AND
					COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
						ie.text_value, ie.float_value, ie.bit_value, ie.date_value), '') <> ''
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = fi.director_id
			WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_poll_id AND 
				fi.director_id IS NOT NULL AND fi.deleted = FALSE
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
	LIMIT COALESCE(vr_count, 20);
END;
$$ LANGUAGE plpgsql;

