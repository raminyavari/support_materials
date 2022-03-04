DROP FUNCTION IF EXISTS fg_get_element_changes;

CREATE OR REPLACE FUNCTION fg_get_element_changes
(
	vr_application_id	UUID,
	vr_element_id		UUID,
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	"row_number"		INTEGER,
	"id"				UUID,
	element_id			UUID,
	"info"				VARCHAR,
	text_value			VARCHAR,
	bit_value			BOOLEAN,
	float_value			FLOAT,
	date_value			TIMESTAMP,
	creation_date		TIMESTAMP,
	creator_user_id		UUID,
	creator_username	VARCHAR,
	creator_first_name	VARCHAR,
	creator_last_name	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM (
			SELECT	(ROW_NUMBER() OVER (ORDER BY "c".id DESC))::INTEGER AS "row_number",
					"c".id,
					"c".element_id,
					efe.info,
					"c".text_value,
					"c".bit_value,
					"c".float_value,
					"c".date_value,
					"c".creation_date,
					"c".creator_user_id,
					un.username AS creator_username,
					un.first_name AS creator_first_name,
					un.last_name AS creator_last_name
			FROM fg_changes AS "c"
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = "c".creator_user_id
				INNER JOIN fg_instance_elements AS e
				ON e.application_id = vr_application_id AND e.element_id = "c".element_id
				INNER JOIN fg_extended_form_elements AS efe
				ON efe.application_id = vr_application_id AND efe.element_id = e.ref_element_id
			WHERE "c".application_id = vr_application_id AND "c".element_id = vr_element_id AND "c".deleted = FALSE
		) AS x
	WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.row_number ASC
	LIMIT COALESCE(vr_count, 10000);
END;
$$ LANGUAGE plpgsql;

